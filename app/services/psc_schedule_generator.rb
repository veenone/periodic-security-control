# frozen_string_literal: true

class PscScheduleGenerator
  class << self
    # Generate issues for all due schedules across all projects
    def generate_due_issues(options = {})
      settings = Setting.plugin_periodic_security_control
      author_id = settings['issue_author_id']
      author = author_id.present? ? User.find_by(id: author_id) : User.current
      author ||= User.find_by(admin: true) || User.first

      generated_count = 0
      errors = []

      PscSchedule.due_for_generation.includes(control_point: { category: :project }).find_each do |schedule|
        project = schedule.control_point&.category&.project
        next unless project

        begin
          issue = schedule.generate_issue!(project, author)
          if issue.persisted?
            generated_count += 1
            Rails.logger.info "[PSC] Generated issue ##{issue.id} for schedule ##{schedule.id}"
          else
            error_msg = "Schedule ##{schedule.id}: #{issue.errors.full_messages.join(', ')}"
            errors << error_msg
            Rails.logger.error "[PSC] Failed to generate issue: #{error_msg}"
          end
        rescue StandardError => e
          error_msg = "Schedule ##{schedule.id}: #{e.message}"
          errors << error_msg
          Rails.logger.error "[PSC] Exception generating issue: #{error_msg}"
        end
      end

      { generated: generated_count, errors: errors }
    end

    # Generate issues for due schedules in a specific project
    def generate_due_issues_for_project(project, options = {})
      settings = Setting.plugin_periodic_security_control
      author_id = settings['issue_author_id']
      author = author_id.present? ? User.find_by(id: author_id) : User.current
      author ||= User.find_by(admin: true) || User.first

      generated_count = 0
      errors = []

      schedules = PscSchedule.due_for_generation
                             .joins(control_point: :category)
                             .where(psc_control_categories: { project_id: project.id })
                             .includes(control_point: :category)

      schedules.find_each do |schedule|
        begin
          issue = schedule.generate_issue!(project, author)
          if issue.persisted?
            generated_count += 1
            Rails.logger.info "[PSC] Generated issue ##{issue.id} for schedule ##{schedule.id}"
          else
            error_msg = "Schedule ##{schedule.id}: #{issue.errors.full_messages.join(', ')}"
            errors << error_msg
            Rails.logger.error "[PSC] Failed to generate issue: #{error_msg}"
          end
        rescue StandardError => e
          error_msg = "Schedule ##{schedule.id}: #{e.message}"
          errors << error_msg
          Rails.logger.error "[PSC] Exception generating issue: #{error_msg}"
        end
      end

      { generated: generated_count, errors: errors }
    end

    def update_overdue_statuses
      updated_count = PscSchedule.pending
                                 .or(PscSchedule.generated)
                                 .where('due_date < ?', Date.current)
                                 .update_all(status: 'overdue', updated_at: Time.current)

      Rails.logger.info "[PSC] Updated #{updated_count} schedules to overdue status"
      updated_count
    end

    def generate_year_schedules(year, control_points = nil)
      control_points ||= PscControlPoint.active

      generated_count = 0
      errors = []

      control_points.find_each do |control_point|
        begin
          control_point.generate_schedules_for_year(year)
          generated_count += 1
        rescue StandardError => e
          error_msg = "Control point #{control_point.full_control_id}: #{e.message}"
          errors << error_msg
          Rails.logger.error "[PSC] Failed to generate schedules: #{error_msg}"
        end
      end

      Rails.logger.info "[PSC] Generated schedules for #{generated_count} control points for year #{year}"
      { generated: generated_count, errors: errors }
    end

    # Generate schedules for a specific project
    def generate_year_schedules_for_project(project, year)
      control_points = PscControlPoint.for_project(project).active
      generate_year_schedules(year, control_points)
    end

    def generate_all_schedules_for_year(year)
      categories = PscControlCategory.active.includes(:control_points)
      total_generated = 0

      categories.each do |category|
        category.control_points.active.each do |control_point|
          control_point.generate_schedules_for_year(year)
          total_generated += control_point.periods_per_year
        end
      end

      Rails.logger.info "[PSC] Generated #{total_generated} total schedules for year #{year}"
      total_generated
    end

    def sync_completed_from_issues
      synced_count = 0

      PscSchedule.generated.includes(:issue).find_each do |schedule|
        next unless schedule.issue&.closed?

        schedule.mark_completed!
        synced_count += 1
      end

      Rails.logger.info "[PSC] Synced #{synced_count} schedules from closed issues"
      synced_count
    end

    def cleanup_orphaned_schedules
      # Remove schedules for deleted control points (shouldn't happen due to cascade, but safety check)
      orphaned = PscSchedule.left_joins(:control_point)
                            .where(psc_control_points: { id: nil })

      count = orphaned.count
      orphaned.destroy_all if count.positive?

      Rails.logger.info "[PSC] Cleaned up #{count} orphaned schedules"
      count
    end

    def reset_schedules_with_missing_issues
      # Reset schedules where the linked issue has been deleted
      reset_count = 0

      PscSchedule.with_missing_issues.find_each do |schedule|
        schedule.reset_orphaned!
        reset_count += 1
      end

      Rails.logger.info "[PSC] Reset #{reset_count} schedules with missing issues"
      reset_count
    end

    def statistics_for_year(year, project = nil)
      schedules = PscSchedule.for_year(year)

      if project
        schedules = schedules.joins(control_point: :category)
                             .where(psc_control_categories: { project_id: project.id })
      end

      {
        year: year,
        total: schedules.count,
        pending: schedules.pending.count,
        generated: schedules.generated.count,
        completed: schedules.completed.count,
        overdue: schedules.overdue.count,
        skipped: schedules.where(status: 'skipped').count,
        completion_rate: calculate_completion_rate(schedules)
      }
    end

    private

    def calculate_completion_rate(schedules)
      total = schedules.count
      return 0 if total.zero?

      completed = schedules.where(status: 'completed').count
      (completed.to_f / total * 100).round(1)
    end
  end
end
