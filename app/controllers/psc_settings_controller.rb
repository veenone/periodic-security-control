# frozen_string_literal: true

class PscSettingsController < ApplicationController
  before_action :find_project
  before_action :authorize

  def edit
    @settings = PscSetting.for_project(@project)
    @trackers = @project.trackers
    @priorities = IssuePriority.active
  end

  def update
    @settings = PscSetting.for_project(@project)
    @settings.safe_attributes = params[:psc_setting]

    if @settings.save
      flash[:notice] = l(:notice_successful_update)
      redirect_to settings_project_path(@project, tab: 'periodic_security_control')
    else
      @trackers = @project.trackers
      @priorities = IssuePriority.active
      render :edit
    end
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end
end
