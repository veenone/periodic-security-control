# frozen_string_literal: true

class PscControlPoint < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  include Redmine::SafeAttributes

  FREQUENCIES = {
    'weekly' => { interval: 1, unit: :week, periods_per_year: 52, label: 'Weekly' },
    'monthly' => { interval: 1, unit: :month, periods_per_year: 12, label: 'Monthly' },
    'quarterly' => { interval: 3, unit: :month, periods_per_year: 4, label: 'Quarterly' },
    'six_monthly' => { interval: 6, unit: :month, periods_per_year: 2, label: '6 Months' },
    'yearly' => { interval: 12, unit: :month, periods_per_year: 1, label: 'Yearly' }
  }.freeze

  belongs_to :category, class_name: 'PscControlCategory'
  belongs_to :tracker, optional: true
  belongs_to :priority, class_name: 'IssuePriority', optional: true
  belongs_to :assigned_to, class_name: 'Principal', optional: true

  has_many :schedules, class_name: 'PscSchedule',
           foreign_key: 'control_point_id', dependent: :destroy

  validates :control_id, presence: true, uniqueness: { case_sensitive: false }
  validates :name, presence: true
  validates :frequency, presence: true, inclusion: { in: FREQUENCIES.keys }
  validates :category, presence: true

  before_validation :format_control_id

  acts_as_positioned scope: [:category_id]

  scope :active, -> { where(active: true) }
  scope :sorted, -> { order(:position) }
  scope :by_frequency, ->(freq) { where(frequency: freq) }
  scope :by_category, ->(category_id) { where(category_id: category_id) }

  safe_attributes 'category_id', 'control_id', 'name', 'description',
                  'frequency', 'position', 'active', 'tracker_id',
                  'priority_id', 'assigned_to_id'

  def to_s
    "#{full_control_id} - #{name}"
  end

  def full_control_id
    control_id.upcase
  end

  def frequency_config
    FREQUENCIES[frequency]
  end

  def frequency_label
    frequency_config&.dig(:label) || frequency.humanize
  end

  def periods_per_year
    frequency_config&.dig(:periods_per_year) || 12
  end

  def next_scheduled_date(from_date = Date.current)
    latest_schedule = schedules.where('scheduled_date >= ?', from_date).order(:scheduled_date).first
    latest_schedule&.scheduled_date || calculate_next_date(from_date)
  end

  def generate_schedules_for_year(year)
    periods = periods_per_year

    (1..periods).each do |period|
      scheduled_date = calculate_scheduled_date(year, period)
      due_date = calculate_due_date(scheduled_date)

      schedules.find_or_create_by(year: year, period_number: period) do |s|
        s.scheduled_date = scheduled_date
        s.due_date = due_date
        s.status = 'pending'
      end
    end
  end

  def calculate_scheduled_date(year, period)
    case frequency
    when 'weekly'
      Date.commercial(year, period, 1) # Monday of the week
    when 'monthly'
      Date.new(year, period, 1)
    when 'quarterly'
      month = ((period - 1) * 3) + 1
      Date.new(year, month, 1)
    when 'six_monthly'
      month = ((period - 1) * 6) + 1
      Date.new(year, month, 1)
    when 'yearly'
      Date.new(year, 1, 1)
    else
      Date.new(year, period, 1)
    end
  end

  def calculate_due_date(scheduled_date)
    case frequency
    when 'weekly'
      scheduled_date + 6.days # End of week (Sunday)
    when 'monthly'
      scheduled_date.end_of_month
    when 'quarterly'
      (scheduled_date + 2.months).end_of_month
    when 'six_monthly'
      (scheduled_date + 5.months).end_of_month
    when 'yearly'
      scheduled_date.end_of_year
    else
      scheduled_date.end_of_month
    end
  end

  def last_completed_schedule
    schedules.where(status: 'completed').order(completed_at: :desc).first
  end

  def overdue_schedules_count
    schedules.overdue.count
  end

  private

  def format_control_id
    self.control_id = control_id.upcase.strip if control_id.present?
  end

  def calculate_next_date(from_date)
    case frequency
    when 'weekly'
      from_date.beginning_of_week
    when 'monthly'
      from_date.beginning_of_month
    when 'quarterly'
      quarter_month = ((from_date.month - 1) / 3) * 3 + 1
      Date.new(from_date.year, quarter_month, 1)
    when 'six_monthly'
      half_month = from_date.month <= 6 ? 1 : 7
      Date.new(from_date.year, half_month, 1)
    when 'yearly'
      Date.new(from_date.year, 1, 1)
    else
      from_date.beginning_of_month
    end
  end
end
