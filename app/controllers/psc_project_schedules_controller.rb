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
    generated_count = 0
    errors = []

    schedules = PscSchedule.due_for_generation
                           .joins(control_point: :category)
                           .where(psc_control_categories: { project_id: @project.id })

    schedules.find_each do |schedule|
      issue = schedule.generate_issue!(@project, User.current)
      if issue.persisted?
        generated_count += 1
      else
        errors << "#{schedule}: #{issue.errors.full_messages.join(', ')}"
      end
    end

    if errors.any?
      flash[:warning] = l(:notice_psc_bulk_generate_partial, count: generated_count, errors: errors.count)
    else
      flash[:notice] = l(:notice_psc_bulk_generate_success, count: generated_count)
    end

    redirect_to project_psc_schedules_path(@project)
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
