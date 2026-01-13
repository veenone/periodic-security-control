# frozen_string_literal: true

class PscDashboardController < ApplicationController
  before_action :require_login
  before_action :authorize_global

  def index
    @year = params[:year]&.to_i || Date.current.year
    @categories = PscControlCategory.active.sorted.includes(control_points: :schedules)

    @statistics = calculate_statistics(@year)
    @monthly_data = calculate_monthly_data(@year)
    @overdue_schedules = PscSchedule.overdue
                                    .includes(control_point: :category)
                                    .order(:due_date)
                                    .limit(10)
    @upcoming_schedules = PscSchedule.pending
                                     .where(scheduled_date: Date.current..(Date.current + 30.days))
                                     .includes(control_point: :category)
                                     .order(:scheduled_date)
                                     .limit(10)
    @category_stats = calculate_category_stats(@year)
  end

  def calendar
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @schedules = PscSchedule.includes(control_point: :category)
                            .where(scheduled_date: start_date..end_date)
                            .order(:scheduled_date)

    @schedules_by_date = @schedules.group_by(&:scheduled_date)
  end

  private

  def authorize_global
    unless User.current.allowed_to_globally?(:view_psc_dashboard)
      deny_access
    end
  end

  def calculate_statistics(year)
    schedules = PscSchedule.for_year(year)

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
      schedules = PscSchedule.for_month(date)

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
    PscControlCategory.active.sorted.map do |category|
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
