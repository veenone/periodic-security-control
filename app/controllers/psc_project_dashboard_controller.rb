# frozen_string_literal: true

class PscProjectDashboardController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize

  def index
    @year = params[:year]&.to_i || Date.current.year
    @categories = @project.psc_control_categories.active.sorted.includes(control_points: :schedules)

    @statistics = calculate_statistics(@year)
    @monthly_data = calculate_monthly_data(@year)
    @overdue_schedules = project_schedules.overdue
                                          .includes(control_point: :category)
                                          .order(:due_date)
                                          .limit(10)
    @upcoming_schedules = project_schedules.pending
                                           .where(scheduled_date: Date.current..(Date.current + 30.days))
                                           .includes(control_point: :category)
                                           .order(:scheduled_date)
                                           .limit(10)
    @category_stats = calculate_category_stats(@year)
  end

  private

  def project_schedules
    PscSchedule.joins(control_point: :category)
               .where(psc_control_categories: { project_id: @project.id })
  end

  def calculate_statistics(year)
    schedules = project_schedules.for_year(year)

    total = schedules.count
    completed = schedules.where(status: 'completed').count
    pending = schedules.where(status: 'pending').count
    generated = schedules.where(status: 'generated').count
    overdue = schedules.where(status: %w[pending generated overdue])
                       .where('due_date < ?', Date.current).count
    skipped = schedules.where(status: 'skipped').count

    completion_rate = total.positive? ? (completed.to_f / total * 100).round(1) : 0

    {
      total: total,
      completed: completed,
      pending: pending,
      generated: generated,
      overdue: overdue,
      skipped: skipped,
      completion_rate: completion_rate
    }
  end

  def calculate_monthly_data(year)
    (1..12).map do |month|
      date = Date.new(year, month, 1)
      schedules = project_schedules.for_month(date)

      total = schedules.count
      completed = schedules.where(status: 'completed').count
      pending = schedules.where(status: %w[pending generated]).count
      overdue = schedules.where(status: %w[pending generated overdue])
                         .where('due_date < ?', Date.current).count

      completion_rate = total.positive? ? (completed.to_f / total * 100).round(0) : 0

      {
        month: month,
        month_name: Date::MONTHNAMES[month],
        month_abbr: Date::ABBR_MONTHNAMES[month],
        total: total,
        completed: completed,
        pending: pending,
        overdue: overdue,
        completion_rate: completion_rate
      }
    end
  end

  def calculate_category_stats(year)
    @project.psc_control_categories.active.sorted.map do |category|
      schedules = PscSchedule.joins(:control_point)
                             .where(psc_control_points: { category_id: category.id })
                             .for_year(year)

      total = schedules.count
      completed = schedules.where(status: 'completed').count
      pending = schedules.where(status: %w[pending generated]).count
      overdue = schedules.where(status: %w[pending generated overdue])
                         .where('due_date < ?', Date.current).count

      completion_rate = total.positive? ? (completed.to_f / total * 100).round(1) : 0

      {
        category: category,
        total: total,
        completed: completed,
        pending: pending,
        overdue: overdue,
        completion_rate: completion_rate
      }
    end
  end
end
