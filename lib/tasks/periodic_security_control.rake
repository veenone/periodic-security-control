# frozen_string_literal: true

namespace :periodic_control do
  desc 'Generate issues for due control schedules'
  task generate_issues: :environment do
    puts "Generating issues for due control schedules..."
    result = PscScheduleGenerator.generate_due_issues
    puts "Generated #{result[:generated]} issues"
    if result[:errors].any?
      puts "Errors:"
      result[:errors].each { |e| puts "  - #{e}" }
    end
  end

  desc 'Update overdue schedule statuses'
  task update_overdue: :environment do
    puts "Updating overdue schedule statuses..."
    count = PscScheduleGenerator.update_overdue_statuses
    puts "Updated #{count} schedules to overdue status"
  end

  desc 'Generate schedules for a specific year (default: current year)'
  task :generate_schedules, [:year] => :environment do |_t, args|
    year = (args[:year] || ENV['YEAR'] || Date.current.year).to_i
    puts "Generating schedules for year #{year}..."
    result = PscScheduleGenerator.generate_year_schedules(year)
    puts "Generated schedules for #{result[:generated]} control points"
    if result[:errors].any?
      puts "Errors:"
      result[:errors].each { |e| puts "  - #{e}" }
    end
  end

  desc 'Generate schedules for next year'
  task generate_next_year_schedules: :environment do
    year = Date.current.year + 1
    puts "Generating schedules for year #{year}..."
    result = PscScheduleGenerator.generate_year_schedules(year)
    puts "Generated schedules for #{result[:generated]} control points"
  end

  desc 'Sync completed schedules from closed issues'
  task sync_completed: :environment do
    puts "Syncing completed schedules from closed issues..."
    count = PscScheduleGenerator.sync_completed_from_issues
    puts "Synced #{count} schedules"
  end

  desc 'Show statistics for a year (default: current year)'
  task :statistics, [:year] => :environment do |_t, args|
    year = (args[:year] || ENV['YEAR'] || Date.current.year).to_i
    stats = PscScheduleGenerator.statistics_for_year(year)
    puts ""
    puts "Control Statistics for #{year}"
    puts "=" * 40
    puts "Total schedules:    #{stats[:total]}"
    puts "Pending:            #{stats[:pending]}"
    puts "Generated (issue):  #{stats[:generated]}"
    puts "Completed:          #{stats[:completed]}"
    puts "Overdue:            #{stats[:overdue]}"
    puts "Skipped:            #{stats[:skipped]}"
    puts "Completion rate:    #{stats[:completion_rate]}%"
    puts ""
  end

  desc 'Cleanup orphaned schedules'
  task cleanup: :environment do
    puts "Cleaning up orphaned schedules..."
    count = PscScheduleGenerator.cleanup_orphaned_schedules
    puts "Cleaned up #{count} orphaned schedules"
  end

  desc 'Reset schedules with missing issues (issues that were deleted)'
  task reset_missing_issues: :environment do
    puts "Resetting schedules with missing issues..."
    count = PscScheduleGenerator.reset_schedules_with_missing_issues
    puts "Reset #{count} schedules with missing issues"
  end

  desc 'Run all daily maintenance tasks'
  task daily: :environment do
    Rake::Task['periodic_control:update_overdue'].invoke
    Rake::Task['periodic_control:reset_missing_issues'].invoke
    Rake::Task['periodic_control:generate_issues'].invoke
    Rake::Task['periodic_control:sync_completed'].invoke
  end

  desc 'Initialize plugin with sample data (for testing)'
  task seed: :environment do
    puts "Creating sample control categories and control points..."

    categories_data = [
      { code: 'ACS', name: 'Access Control System', description: 'Physical access controls for badge management and access reviews' },
      { code: 'AMS', name: 'Alarm Management System', description: 'Alarm monitoring and response controls' },
      { code: 'VSS', name: 'Video Surveillance System', description: 'CCTV and video surveillance controls' },
      { code: 'VAM', name: 'Visitor Access Management', description: 'Visitor handling and access controls' },
      { code: 'IRM', name: 'Incident and Risk Management', description: 'Incident tracking and risk management controls' },
      { code: 'OPM', name: 'Security Operational Management', description: 'General security operations controls' },
      { code: 'TCM', name: 'Test Cards Management', description: 'Test card tracking and management controls' }
    ]

    control_points_data = {
      'ACS' => [
        { control_id: 'ACS01', name: 'Access Control System functionalities checking', frequency: 'weekly' },
        { control_id: 'ACS03', name: 'Unused badges destruction', frequency: 'quarterly' },
        { control_id: 'ACS04', name: 'Badges stock and inventory review', frequency: 'monthly' },
        { control_id: 'ACS05', name: 'IPP Masterlist review', frequency: 'monthly' },
        { control_id: 'ACS07', name: 'Access Control Request review', frequency: 'monthly' },
        { control_id: 'ACS12', name: 'Checking irrelevant physical site access', frequency: 'monthly' },
        { control_id: 'ACS15', name: 'Badge & Test Card tracking review', frequency: 'monthly' },
        { control_id: 'ACS16', name: 'Access Rights Management Review', frequency: 'six_monthly' }
      ],
      'AMS' => [
        { control_id: 'AMS01', name: 'Alarm system quarterly test', frequency: 'quarterly' },
        { control_id: 'AMS02', name: 'Alarm response review', frequency: 'monthly' },
        { control_id: 'AMS03', name: 'Alarm log review', frequency: 'monthly' }
      ],
      'VSS' => [
        { control_id: 'VSS01', name: 'CCTV system quarterly check', frequency: 'quarterly' },
        { control_id: 'VSS02', name: 'Video storage capacity review', frequency: 'monthly' },
        { control_id: 'VSS03', name: 'Camera coverage audit', frequency: 'monthly' }
      ],
      'VAM' => [
        { control_id: 'VAM01', name: 'Visitor log review', frequency: 'monthly' },
        { control_id: 'VAM02', name: 'Visitor badge inventory', frequency: 'monthly' }
      ],
      'IRM' => [
        { control_id: 'IRM01', name: 'Incident report quarterly review', frequency: 'quarterly' },
        { control_id: 'IRM02', name: 'Security incident trend analysis', frequency: 'monthly' },
        { control_id: 'IRM03', name: 'Risk assessment review', frequency: 'monthly' }
      ],
      'OPM' => [
        { control_id: 'OPM01', name: 'Security guard schedule review', frequency: 'monthly' },
        { control_id: 'OPM02', name: 'Patrol log review', frequency: 'monthly' },
        { control_id: 'OPM03', name: 'Security equipment check', frequency: 'monthly' },
        { control_id: 'OPM04', name: 'Security briefing', frequency: 'weekly' },
        { control_id: 'OPM05', name: 'Emergency drill', frequency: 'quarterly' },
        { control_id: 'OPM06', name: 'Security policy annual review', frequency: 'yearly' },
        { control_id: 'OPM07', name: 'Vendor security assessment', frequency: 'six_monthly' }
      ],
      'TCM' => [
        { control_id: 'TCM01', name: 'Test card inventory', frequency: 'monthly' },
        { control_id: 'TCM02', name: 'Test card audit', frequency: 'quarterly' }
      ]
    }

    categories_data.each_with_index do |cat_data, index|
      category = PscControlCategory.find_or_create_by!(code: cat_data[:code]) do |c|
        c.name = cat_data[:name]
        c.description = cat_data[:description]
        c.position = index + 1
      end
      puts "  Created category: #{category.code} - #{category.name}"

      control_points_data[cat_data[:code]]&.each_with_index do |cp_data, cp_index|
        control_point = category.control_points.find_or_create_by!(control_id: cp_data[:control_id]) do |cp|
          cp.name = cp_data[:name]
          cp.frequency = cp_data[:frequency]
          cp.position = cp_index + 1
        end
        puts "    Created control point: #{control_point.full_control_id} - #{control_point.name}"
      end
    end

    puts ""
    puts "Generating schedules for current year..."
    Rake::Task['periodic_control:generate_schedules'].invoke(Date.current.year)

    puts ""
    puts "Sample data created successfully!"
  end
end
