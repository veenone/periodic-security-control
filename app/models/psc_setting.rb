# frozen_string_literal: true

class PscSetting < (defined?(ApplicationRecord) == 'constant' ? ApplicationRecord : ActiveRecord::Base)
  include Redmine::SafeAttributes

  belongs_to :project
  belongs_to :default_tracker, class_name: 'Tracker', optional: true
  belongs_to :default_priority, class_name: 'IssuePriority', optional: true

  validates :project_id, presence: true, uniqueness: true

  safe_attributes 'default_tracker_id', 'default_priority_id',
                  'issue_subject_template', 'issue_description_template',
                  'advance_days', 'enable_auto_generation'

  def self.for_project(project)
    find_or_create_by(project: project) do |s|
      s.issue_subject_template = Setting.plugin_periodic_security_control['issue_subject_template'] ||
                                 '[{{control_id}}] {{control_name}} - {{period}} {{year}}'
      s.issue_description_template = Setting.plugin_periodic_security_control['issue_description_template'] ||
                                     default_description_template
      s.advance_days = Setting.plugin_periodic_security_control['advance_days'].to_i
      s.advance_days = 7 if s.advance_days <= 0
      s.enable_auto_generation = true
    end
  end

  def self.default_description_template
    <<~TEMPLATE
      Security Control Check

      Category: {{category}}
      Control: {{control_id}} - {{control_name}}
      Period: {{period}} {{year}}
      Frequency: {{frequency}}
      Scheduled Date: {{scheduled_date}}
      Due Date: {{due_date}}
    TEMPLATE
  end

  def issue_subject_template
    super.presence || '[{{control_id}}] {{control_name}} - {{period}} {{year}}'
  end

  def issue_description_template
    super.presence || self.class.default_description_template
  end

  def advance_days
    val = super
    val.present? && val > 0 ? val : 7
  end
end
