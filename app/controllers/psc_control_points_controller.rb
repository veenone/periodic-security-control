# frozen_string_literal: true

class PscControlPointsController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_category
  before_action :find_control_point, only: [:show, :edit, :update, :destroy, :generate_schedules]

  helper :sort
  include SortHelper

  def index
    sort_init 'position', 'asc'
    sort_update %w[position control_id name frequency]

    @control_points = @category.control_points.sorted.includes(:tracker, :priority, :assigned_to)
  end

  def show
    @schedules = @control_point.schedules
                               .order(year: :desc, period_number: :desc)
                               .page(params[:page])
                               .per_page(25)
  end

  def new
    @control_point = @category.control_points.build
    @control_point.frequency = 'monthly'
  end

  def create
    @control_point = @category.control_points.build
    @control_point.safe_attributes = params[:psc_control_point]

    if @control_point.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to psc_category_path(@category)
    else
      render :new
    end
  end

  def edit
  end

  def update
    @control_point.safe_attributes = params[:psc_control_point]

    if @control_point.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to psc_category_path(@category)
    else
      render :edit
    end
  end

  def destroy
    if @control_point.schedules.where.not(issue_id: nil).any?
      flash[:error] = l(:error_psc_control_point_has_issues)
      redirect_to psc_category_path(@category)
    else
      @control_point.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to psc_category_path(@category)
    end
  end

  def generate_schedules
    year = params[:year]&.to_i || Date.current.year

    begin
      @control_point.generate_schedules_for_year(year)
      flash[:notice] = l(:notice_psc_schedules_generated, year: year)
    rescue StandardError => e
      flash[:error] = l(:error_psc_schedules_generation_failed, message: e.message)
    end

    redirect_to psc_category_psc_control_point_path(@category, @control_point)
  end

  def bulk_generate_schedules
    year = params[:year]&.to_i || Date.current.year
    generated_count = 0

    @category.control_points.active.find_each do |control_point|
      control_point.generate_schedules_for_year(year)
      generated_count += 1
    end

    flash[:notice] = l(:notice_psc_bulk_schedules_generated, count: generated_count, year: year)
    redirect_to psc_category_path(@category)
  end

  private

  def find_category
    @category = PscControlCategory.find(params[:psc_category_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def find_control_point
    @control_point = @category.control_points.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
