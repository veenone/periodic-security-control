# frozen_string_literal: true

class PscCategoriesController < ApplicationController
  layout 'admin'

  before_action :require_admin
  before_action :find_category, only: [:show, :edit, :update, :destroy]

  helper :sort
  include SortHelper

  def index
    sort_init 'position', 'asc'
    sort_update %w[position name code]

    @categories = PscControlCategory.sorted.includes(:control_points)

    respond_to do |format|
      format.html
      format.api
    end
  end

  def show
    @control_points = @category.control_points.sorted.includes(:tracker, :priority, :assigned_to)
  end

  def new
    @category = PscControlCategory.new
  end

  def create
    @category = PscControlCategory.new
    @category.safe_attributes = params[:psc_control_category]

    if @category.save
      flash[:notice] = l(:notice_successful_create)
      redirect_to psc_categories_path
    else
      render :new
    end
  end

  def edit
  end

  def update
    @category.safe_attributes = params[:psc_control_category]

    if @category.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to psc_categories_path
    else
      render :edit
    end
  end

  def destroy
    if @category.control_points.any?
      flash[:error] = l(:error_psc_category_has_control_points)
      redirect_to psc_categories_path
    else
      @category.destroy
      flash[:notice] = l(:notice_successful_delete)
      redirect_to psc_categories_path
    end
  end

  def import
    if params[:file].blank?
      flash[:error] = l(:error_no_file_selected)
      redirect_to psc_categories_path
      return
    end

    begin
      imported_count = import_from_file(params[:file])
      flash[:notice] = l(:notice_psc_import_successful, count: imported_count)
    rescue StandardError => e
      flash[:error] = l(:error_psc_import_failed, message: e.message)
    end

    redirect_to psc_categories_path
  end

  def export
    @categories = PscControlCategory.sorted.includes(control_points: [:tracker, :priority])

    respond_to do |format|
      format.csv do
        send_data export_to_csv, filename: "security_controls_#{Date.current.iso8601}.csv"
      end
    end
  end

  private

  def find_category
    @category = PscControlCategory.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def import_from_file(file)
    require 'csv'
    imported = 0

    CSV.foreach(file.path, headers: true) do |row|
      category = PscControlCategory.find_or_initialize_by(code: row['code'].to_s.upcase)
      category.name = row['name'] if row['name'].present?
      category.description = row['description']
      category.active = row['active'] != 'false'

      if category.save
        # Import control points if present
        if row['control_id'].present?
          control_point = category.control_points.find_or_initialize_by(control_id: row['control_id'].upcase)
          control_point.name = row['control_name'] if row['control_name'].present?
          control_point.description = row['control_description']
          control_point.frequency = row['frequency'] if PscControlPoint::FREQUENCIES.key?(row['frequency'])
          control_point.active = row['control_active'] != 'false'
          control_point.save
        end

        imported += 1
      end
    end

    imported
  end

  def export_to_csv
    require 'csv'

    CSV.generate(headers: true) do |csv|
      csv << %w[code name description active control_id control_name control_description frequency control_active]

      @categories.each do |category|
        if category.control_points.empty?
          csv << [category.code, category.name, category.description, category.active, '', '', '', '', '']
        else
          category.control_points.each do |cp|
            csv << [
              category.code, category.name, category.description, category.active,
              cp.control_id, cp.name, cp.description, cp.frequency, cp.active
            ]
          end
        end
      end
    end
  end
end
