# frozen_string_literal: true

class PscProjectSchedulesController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_schedule, only: [:show, :edit, :update, :generate_issue, :skip, :complete, :reopen]

  helper :sort
  include SortHelper

  def index
    sort_init 'scheduled_date', 'asc'
    sort_update %w[scheduled_date due_date status year]

    @year = params[:year]&.to_i || Date.current.year
    @status_filter = params[:status]
    @category_filter = params[:category_id]

    @schedules = PscSchedule.joins(control_point: :category)
                            .where(psc_control_categories: { project_id: @project.id })
                            .includes(control_point: :category)
                            .for_year(@year)
                            .order(sort_clause)

    @schedules = @schedules.where(status: @status_filter) if @status_filter.present?
    @schedules = @schedules.by_category(@category_filter) if @category_filter.present?

    @schedule_count = @schedules.count
    @schedule_pages = Paginator.new @schedule_count, per_page_option, params['page']
    @schedules = @schedules.limit(@schedule_pages.per_page).offset(@schedule_pages.offset)

    @categories = @project.psc_control_categories.active.sorted
  end

  def show
  end

  def edit
  end

  def update
    @schedule.safe_attributes = params[:psc_schedule]

    if @schedule.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_psc_schedule_path(@project, @schedule)
    else
      render :edit
    end
  end

  def calendar
    @year = params[:year]&.to_i || Date.current.year
    @month = params[:month]&.to_i || Date.current.month

    start_date = Date.new(@year, @month, 1)
    end_date = start_date.end_of_month

    @schedules = PscSchedule.joins(control_point: :category)
                            .where(psc_control_categories: { project_id: @project.id })
                            .includes(control_point: :category)
                            .where(scheduled_date: start_date..end_date)
                            .order(:scheduled_date)

    @schedules_by_date = @schedules.group_by(&:scheduled_date)
  end

  def generate_issue
    issue = @schedule.generate_issue!(@project, User.current)

    if issue.persisted?
      flash[:notice] = l(:notice_psc_issue_generated, issue_id: issue.id)
    else
      flash[:error] = l(:error_psc_issue_generation_failed, errors: issue.errors.full_messages.join(', '))
    end

    redirect_back fallback_location: project_psc_schedules_path(@project)
  end

  def skip
    @schedule.skip!(params[:notes])
    flash[:notice] = l(:notice_psc_schedule_skipped)
    redirect_back fallback_location: project_psc_schedules_path(@project)
  end

  def complete
    @schedule.mark_completed!
    flash[:notice] = l(:notice_psc_schedule_completed)
    redirect_back fallback_location: project_psc_schedules_path(@project)
  end

  def reopen
    @schedule.reopen!
    flash[:notice] = l(:notice_psc_schedule_reopened)
    redirect_back fallback_location: project_psc_schedules_path(@project)
  end

  def bulk_generate
    year = params[:year]&.to_i || Date.current.year
    generated_count = 0
    schedule_count = 0
    reset_count = 0
    errors = []

    # First, generate schedules for all active control points for the year
    control_points = PscControlPoint.for_project(@project).active.includes(:category)
    control_points.find_each do |control_point|
      control_point.generate_schedules_for_year(year)
      schedule_count += 1
    end

    # Reset schedules where linked issue was deleted
    orphaned_schedules = PscSchedule.with_missing_issues
                                    .joins(control_point: :category)
                                    .where(psc_control_categories: { project_id: @project.id })
                                    .for_year(year)
    orphaned_schedules.find_each do |schedule|
      schedule.reset_orphaned!
      reset_count += 1
    end

    # Get project settings for advance_days
    settings = PscSetting.for_project(@project)
    advance_days = settings&.advance_days || 7

    # Then generate issues for all due schedules (pending status)
    schedules = PscSchedule.pending
                           .joins(control_point: :category)
                           .where(psc_control_categories: { project_id: @project.id })
                           .where('scheduled_date <= ?', Date.current + advance_days.days)

    schedules.find_each do |schedule|
      issue = schedule.generate_issue!(@project, User.current)
      if issue.persisted?
        generated_count += 1
      else
        errors << "#{schedule}: #{issue.errors.full_messages.join(', ')}"
      end
    end

    messages = []
    messages << l(:notice_psc_orphaned_schedules_reset, count: reset_count) if reset_count > 0

    if errors.any?
      messages << l(:notice_psc_bulk_generate_partial, count: generated_count, errors: errors.count)
      flash[:warning] = messages.join(' ')
    elsif generated_count > 0
      messages << l(:notice_psc_bulk_generate_success, count: generated_count)
      flash[:notice] = messages.join(' ')
    else
      messages << l(:notice_psc_schedules_generated_no_issues, schedule_count: schedule_count)
      flash[:notice] = messages.join(' ')
    end

    redirect_to project_psc_schedules_path(@project, year: year)
  end

  private

  def find_schedule
    @schedule = PscSchedule.joins(control_point: :category)
                           .where(psc_control_categories: { project_id: @project.id })
                           .includes(control_point: :category)
                           .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
