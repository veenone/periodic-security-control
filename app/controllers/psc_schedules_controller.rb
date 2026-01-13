# frozen_string_literal: true

class PscSchedulesController < ApplicationController
  before_action :require_login
  before_action :authorize_global, only: [:index, :show, :calendar]
  before_action :find_schedule, only: [:show, :edit, :update, :generate_issue, :skip, :complete, :reopen]

  helper :sort
  include SortHelper

  def index
    sort_init 'scheduled_date', 'asc'
    sort_update %w[scheduled_date due_date status year]

    @year = params[:year]&.to_i || Date.current.year
    @status_filter = params[:status]
    @category_filter = params[:category_id]

    @schedules = PscSchedule.includes(control_point: :category)
                            .for_year(@year)
                            .order(sort_clause)

    @schedules = @schedules.where(status: @status_filter) if @status_filter.present?
    @schedules = @schedules.by_category(@category_filter) if @category_filter.present?

    @schedules = @schedules.page(params[:page]).per_page(50)

    @categories = PscControlCategory.active.sorted
  end

  def show
  end

  def edit
  end

  def update
    @schedule.safe_attributes = params[:psc_schedule]

    if @schedule.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to psc_schedule_path(@schedule)
    else
      render :edit
    end
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

  def generate_issue
    project_id = Setting.plugin_periodic_security_control['default_project_id']

    if project_id.blank?
      flash[:error] = l(:error_psc_no_default_project)
      redirect_to psc_schedules_path
      return
    end

    project = Project.find_by(id: project_id)
    unless project
      flash[:error] = l(:error_psc_project_not_found)
      redirect_to psc_schedules_path
      return
    end

    issue = @schedule.generate_issue!(project, User.current)

    if issue.persisted?
      flash[:notice] = l(:notice_psc_issue_generated, issue_id: issue.id)
    else
      flash[:error] = l(:error_psc_issue_generation_failed, errors: issue.errors.full_messages.join(', '))
    end

    redirect_back fallback_location: psc_schedules_path
  end

  def skip
    @schedule.skip!(params[:notes])
    flash[:notice] = l(:notice_psc_schedule_skipped)
    redirect_back fallback_location: psc_schedules_path
  end

  def complete
    @schedule.mark_completed!
    flash[:notice] = l(:notice_psc_schedule_completed)
    redirect_back fallback_location: psc_schedules_path
  end

  def reopen
    @schedule.reopen!
    flash[:notice] = l(:notice_psc_schedule_reopened)
    redirect_back fallback_location: psc_schedules_path
  end

  def bulk_generate
    project_id = Setting.plugin_periodic_security_control['default_project_id']

    if project_id.blank?
      flash[:error] = l(:error_psc_no_default_project)
      redirect_to psc_schedules_path
      return
    end

    project = Project.find_by(id: project_id)
    unless project
      flash[:error] = l(:error_psc_project_not_found)
      redirect_to psc_schedules_path
      return
    end

    generated_count = 0
    errors = []

    PscSchedule.due_for_generation.find_each do |schedule|
      issue = schedule.generate_issue!(project, User.current)
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

    redirect_to psc_schedules_path
  end

  def update_overdue
    updated_count = PscSchedule.pending
                               .or(PscSchedule.generated)
                               .where('due_date < ?', Date.current)
                               .update_all(status: 'overdue')

    flash[:notice] = l(:notice_psc_overdue_updated, count: updated_count)
    redirect_to psc_schedules_path
  end

  private

  def find_schedule
    @schedule = PscSchedule.includes(control_point: :category).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_global
    unless User.current.allowed_to_globally?(:view_psc_dashboard)
      deny_access
    end
  end
end
