# frozen_string_literal: true

class PscSchedule < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  include Redmine::SafeAttributes

  STATUSES = %w[pending generated completed overdue skipped].freeze

  belongs_to :control_point, class_name: 'PscControlPoint'
  belongs_to :issue, optional: true

  validates :year, presence: true,
            numericality: { only_integer: true, greater_than: 2000, less_than: 2100 }
  validates :period_number, presence: true,
            numericality: { only_integer: true, greater_than: 0 }
  validates :scheduled_date, presence: true
  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :control_point_id, uniqueness: { scope: [:year, :period_number],
            message: :schedule_already_exists }

  scope :for_year, ->(year) { where(year: year) }
  scope :for_month, ->(date) { where(scheduled_date: date.beginning_of_month..date.end_of_month) }
  scope :pending, -> { where(status: 'pending') }
  scope :generated, -> { where(status: 'generated') }
  scope :completed, -> { where(status: 'completed') }
  scope :overdue, -> { where(status: %w[pending generated]).where('due_date < ?', Date.current) }
  scope :due_soon, ->(days = 7) { pending.where(scheduled_date: Date.current..(Date.current + days.days)) }
  scope :due_for_generation, lambda {
    advance_days = Setting.plugin_periodic_security_control['advance_days'].to_i
    pending.where('scheduled_date <= ?', Date.current + advance_days.days)
  }
  scope :upcoming, ->(days = 30) { where(scheduled_date: Date.current..(Date.current + days.days)) }
  scope :by_category, ->(category_id) {
    joins(:control_point).where(psc_control_points: { category_id: category_id })
  }

  safe_attributes 'status', 'notes', 'scheduled_date', 'due_date'

  def to_s
    "#{control_point.full_control_id} - #{period_label} #{year}"
  end

  def period_label
    case control_point.frequency
    when 'weekly'
      I18n.t('psc.period.week', number: period_number)
    when 'monthly'
      Date::MONTHNAMES[period_number]
    when 'quarterly'
      "Q#{period_number}"
    when 'six_monthly'
      "H#{period_number}"
    when 'yearly'
      year.to_s
    else
      period_number.to_s
    end
  end

  def generate_issue!(project, author)
    return issue if issue.present?

    settings = PscSetting.for_project(project)
    control = control_point

    new_issue = Issue.new(
      project: project,
      tracker: control.tracker || settings.default_tracker || project.trackers.first,
      priority: control.priority || settings.default_priority || IssuePriority.default,
      author: author,
      assigned_to: control.assigned_to,
      subject: render_template(settings.issue_subject_template),
      description: render_template(settings.issue_description_template),
      start_date: scheduled_date,
      due_date: due_date
    )

    if new_issue.save
      update!(issue: new_issue, status: 'generated', generated_at: Time.current)
    end

    new_issue
  end

  def mark_completed!
    update!(status: 'completed', completed_at: Time.current)
  end

  def mark_overdue!
    return if status == 'completed' || status == 'skipped'

    update!(status: 'overdue')
  end

  def skip!(notes = nil)
    update!(status: 'skipped', notes: notes)
  end

  def reopen!
    update!(status: issue.present? ? 'generated' : 'pending', completed_at: nil)
  end

  def pending?
    status == 'pending'
  end

  def generated?
    status == 'generated'
  end

  def completed?
    status == 'completed'
  end

  def overdue?
    status == 'overdue' || (status.in?(%w[pending generated]) && due_date && due_date < Date.current)
  end

  def skipped?
    status == 'skipped'
  end

  def days_until_due
    return nil unless due_date

    (due_date - Date.current).to_i
  end

  def days_overdue
    return 0 unless overdue?

    (Date.current - due_date).to_i
  end

  def status_css_class
    case status
    when 'completed' then 'psc-status-completed'
    when 'overdue' then 'psc-status-overdue'
    when 'generated' then 'psc-status-generated'
    when 'skipped' then 'psc-status-skipped'
    else 'psc-status-pending'
    end
  end

  private

  def render_template(template)
    return '' if template.blank?

    template.to_s
            .gsub('{{control_id}}', control_point.full_control_id)
            .gsub('{{control_name}}', control_point.name)
            .gsub('{{category}}', control_point.category.name)
            .gsub('{{period}}', period_label)
            .gsub('{{year}}', year.to_s)
            .gsub('{{frequency}}', control_point.frequency_label)
            .gsub('{{scheduled_date}}', I18n.l(scheduled_date))
            .gsub('{{due_date}}', due_date ? I18n.l(due_date) : '')
  end
end
