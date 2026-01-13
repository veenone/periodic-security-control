# frozen_string_literal: true

RedmineApp::Application.routes.draw do
  # Global dashboard
  get 'psc_dashboard', to: 'psc_dashboard#index', as: 'psc_dashboard'
  get 'psc_dashboard/calendar', to: 'psc_dashboard#calendar', as: 'psc_dashboard_calendar'

  # Admin routes for categories and control points
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

  # Schedule management (global)
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
    resource :psc_settings, only: [:edit, :update]

    resources :psc_schedules, only: [:index, :show], controller: 'psc_project_schedules' do
      member do
        post 'generate_issue'
        post 'skip'
        post 'complete'
      end
      collection do
        get 'calendar'
        post 'bulk_generate'
      end
    end
  end
end
