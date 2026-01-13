# frozen_string_literal: true

module PeriodicSecurityControl
  module IssuePatch
    extend ActiveSupport::Concern

    included do
      has_one :psc_schedule, class_name: 'PscSchedule', foreign_key: 'issue_id', dependent: :nullify

      after_save :sync_psc_schedule_status, if: :saved_change_to_status_id?
    end

    def psc_control_point
      psc_schedule&.control_point
    end

    def psc_linked?
      psc_schedule.present?
    end

    private

    def sync_psc_schedule_status
      return unless psc_schedule.present?

      if status.is_closed?
        psc_schedule.mark_completed! unless psc_schedule.completed?
      elsif psc_schedule.completed?
        # Issue was reopened - revert schedule status
        psc_schedule.reopen!
      end
    end
  end
end
