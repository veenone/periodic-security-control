# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  # Global dashboard (cross-project view)
  get 'psc_dashboard', to: 'psc_dashboard#index', as: 'psc_dashboard'
  get 'psc_dashboard/calendar', to: 'psc_dashboard#calendar', as: 'psc_dashboard_calendar'

  # Global schedule management (admin)
  resources :psc_schedules, only: [:index, :show, :edit, :update] do
    member do
      post 'generate_issue'
      post 'skip'
      post 'complete'
      post 'reopen'
    end
    collection do
      get 'calendar'
      post 'bulk_generate'
      post 'update_overdue'
    end
  end

  # Project-scoped routes
  resources :projects, only: [] do
    # Project settings for PSC
    resource :psc_settings, only: [:edit, :update] do
      get 'tracker_statuses', on: :collection
    end

    # Project-scoped control points (standalone, not nested under categories)
    resources :psc_control_points, controller: 'psc_project_control_points' do
      member do
        post 'generate_schedules'
      end
    end

    # Project-scoped categories with nested control points
    resources :psc_categories do
      collection do
        post 'import'
        get 'export'
      end

      resources :psc_control_points do
        member do
          post 'generate_schedules'
        end
        collection do
          post 'bulk_generate_schedules'
        end
      end
    end

    # Project-scoped schedules
    resources :psc_schedules, only: [:index, :show, :edit, :update], controller: 'psc_project_schedules' do
      member do
        post 'generate_issue'
        post 'skip'
        post 'complete'
        post 'reopen'
      end
      collection do
        get 'calendar'
        post 'bulk_generate'
      end
    end

    # Project dashboard
    get 'psc_dashboard', to: 'psc_project_dashboard#index', as: 'psc_project_dashboard'
  end
end
