# frozen_string_literal: true

class PscProjectControlPointsController < ApplicationController
  before_action :find_project_by_project_id
  before_action :authorize
  before_action :find_control_point, only: [:show, :edit, :update, :destroy, :generate_schedules]

  helper :sort
  include SortHelper

  def index
    sort_init 'control_id', 'asc'
    sort_update %w[control_id name frequency category_id active]

    @control_points = PscControlPoint.for_project(@project)
                                     .includes(:category, :tracker, :priority, :assigned_to, :owner)

    # Filters
    @category_filter = params[:category_id]
    @frequency_filter = params[:frequency]
    @status_filter = params[:status]

    @control_points = @control_points.where(category_id: @category_filter) if @category_filter.present?
    @control_points = @control_points.where(frequency: @frequency_filter) if @frequency_filter.present?

    if @status_filter.present?
      @control_points = @status_filter == 'active' ? @control_points.active : @control_points.where(active: false)
    end

    @control_points = @control_points.order(sort_clause)

    @control_point_count = @control_points.count
    @control_point_pages = Paginator.new @control_point_count, per_page_option, params['page']
    @control_points = @control_points.limit(@control_point_pages.per_page).offset(@control_point_pages.offset)

    @categories = @project.psc_control_categories.active.sorted
  end

  def show
    @category = @control_point.category
    schedules_query = @control_point.schedules.order(year: :desc, period_number: :desc)
    @schedule_count = schedules_query.count
    @schedule_pages = Paginator.new @schedule_count, 25, params['page']
    @schedules = schedules_query.limit(@schedule_pages.per_page).offset(@schedule_pages.offset)
  end

  def new
    @control_point = PscControlPoint.new
    @control_point.frequency = 'monthly'
    @control_point.active = true
    @categories = @project.psc_control_categories.active.sorted
  end

  def create
    @control_point = PscControlPoint.new
    @control_point.safe_attributes = params[:psc_control_point]
    @categories = @project.psc_control_categories.active.sorted

    # Ensure the category belongs to the project
    if @control_point.category && @control_point.category.project_id != @project.id
      @control_point.errors.add(:category_id, :invalid)
      render :new
      return
    end

    if @control_point.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to project_psc_control_points_path(@project)
    else
      render :new
    end
  end

  def edit
    @categories = @project.psc_control_categories.active.sorted
  end

  def update
    @control_point.safe_attributes = params[:psc_control_point]
    @categories = @project.psc_control_categories.active.sorted

    # Ensure the category belongs to the project
    if @control_point.category && @control_point.category.project_id != @project.id
      @control_point.errors.add(:category_id, :invalid)
      render :edit
      return
    end

    if @control_point.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to project_psc_control_point_path(@project, @control_point)
    else
      render :edit
    end
  end

  def destroy
    if @control_point.schedules.where.not(issue_id: nil).any?
      flash[:error] = l(:error_psc_control_point_has_issues)
    else
      @control_point.destroy
      flash[:notice] = l(:notice_successful_delete)
    end
    redirect_to project_psc_control_points_path(@project)
  end

  def generate_schedules
    year = params[:year]&.to_i || Date.current.year

    begin
      @control_point.generate_schedules_for_year(year)
      flash[:notice] = l(:notice_psc_schedules_generated, year: year)
    rescue StandardError => e
      flash[:error] = l(:error_psc_schedules_generation_failed, message: e.message)
    end

    redirect_to project_psc_control_point_path(@project, @control_point)
  end

  private

  def find_control_point
    @control_point = PscControlPoint.for_project(@project)
                                    .includes(:category, :tracker, :priority, :assigned_to, :owner)
                                    .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
