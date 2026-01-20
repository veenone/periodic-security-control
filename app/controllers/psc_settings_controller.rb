# frozen_string_literal: true

class PscSettingsController < ApplicationController
  before_action :find_project
  before_action :authorize, except: [:tracker_statuses]
  before_action :authorize_tracker_statuses, only: [:tracker_statuses]

  def edit
    @settings = PscSetting.for_project(@project)
    @trackers = @project.trackers
    @priorities = IssuePriority.active
    @statuses = statuses_for_tracker(@settings.default_tracker_id)
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
      @statuses = statuses_for_tracker(@settings.default_tracker_id)
      render :edit
    end
  end

  def tracker_statuses
    tracker_id = params[:tracker_id]
    statuses = statuses_for_tracker(tracker_id)

    render json: statuses.map { |s| { id: s.id, name: s.name } }
  end

  private

  def find_project
    @project = Project.find(params[:project_id])
  rescue ActiveRecord::RecordNotFound
    render_404
  end

  def authorize_tracker_statuses
    authorize_global unless User.current.allowed_to?(:configure_psc_settings, @project)
  end

  def statuses_for_tracker(tracker_id)
    return [] if tracker_id.blank?

    tracker = @project.trackers.find_by(id: tracker_id)
    return [] unless tracker

    tracker.issue_statuses.sorted
  end
end
