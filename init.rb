# frozen_string_literal: true

require 'redmine'

# Require lib files
require_relative 'lib/periodic_security_control/hooks'
require_relative 'lib/periodic_security_control/issue_patch'
require_relative 'lib/periodic_security_control/project_patch'

# Apply patches after Rails initialization
Rails.application.config.after_initialize do
  Issue.include(PeriodicSecurityControl::IssuePatch) unless Issue.included_modules.include?(PeriodicSecurityControl::IssuePatch)
  Project.include(PeriodicSecurityControl::ProjectPatch) unless Project.included_modules.include?(PeriodicSecurityControl::ProjectPatch)
end

# Also apply in to_prepare for development mode reloading
Rails.application.config.to_prepare do
  Issue.include(PeriodicSecurityControl::IssuePatch) unless Issue.included_modules.include?(PeriodicSecurityControl::IssuePatch)
  Project.include(PeriodicSecurityControl::ProjectPatch) unless Project.included_modules.include?(PeriodicSecurityControl::ProjectPatch)
end

Redmine::Plugin.register :periodic_security_control do
  name 'Periodic Control'
  author 'Security Team'
  description 'Manages periodic control schedules and auto-generates issues for tracking compliance activities'
  version '1.0.0'
  url 'https://github.com/yourorg/redmine_periodic_security_control'
  author_url 'https://yourorg.com'

  requires_redmine version_or_higher: '5.0.0'

  # Global plugin settings
  settings default: {
    'issue_author_id' => nil,
    'advance_days' => '7',
    'enable_auto_generation' => 'true'
  }, partial: 'settings/periodic_security_control_settings'

  # Application menu (global dashboard)
  menu :application_menu, :psc_dashboard,
       { controller: 'psc_dashboard', action: 'index' },
       caption: :label_psc_dashboard,
       if: Proc.new { User.current.logged? && User.current.allowed_to_globally?(:view_psc_dashboard) }

  # Project menu - Main "Periodic Control" menu item (points to dashboard)
  menu :project_menu, :periodic_security_control,
       { controller: 'psc_project_dashboard', action: 'index' },
       caption: :label_periodic_security_control,
       after: :activity,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_dashboard, project)
       }

  # Sub-menu: Dashboard
  menu :project_menu, :psc_dashboard,
       { controller: 'psc_project_dashboard', action: 'index' },
       caption: :label_psc_dashboard,
       parent: :periodic_security_control,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_dashboard, project)
       }

  # Sub-menu: Control Points
  menu :project_menu, :psc_control_points,
       { controller: 'psc_project_control_points', action: 'index' },
       caption: :label_psc_control_points,
       parent: :periodic_security_control,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_categories, project)
       }

  # Sub-menu: Control Categories
  menu :project_menu, :psc_categories,
       { controller: 'psc_categories', action: 'index' },
       caption: :label_psc_categories,
       parent: :periodic_security_control,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_categories, project)
       }

  # Sub-menu: Control Schedules
  menu :project_menu, :psc_schedules,
       { controller: 'psc_project_schedules', action: 'index' },
       caption: :label_psc_schedules,
       parent: :periodic_security_control,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_schedules, project)
       }

  # Sub-menu: Settings
  menu :project_menu, :psc_settings,
       { controller: 'psc_settings', action: 'edit' },
       caption: :label_settings,
       parent: :periodic_security_control,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:configure_psc_settings, project)
       }

  # Project module definition
  project_module :periodic_security_control do
    # View permissions
    permission :view_psc_dashboard, {
      psc_dashboard: [:index, :calendar],
      psc_project_dashboard: [:index]
    }, public: true, read: true
    permission :view_psc_categories, {
      psc_categories: [:index, :show],
      psc_control_points: [:index, :show],
      psc_project_control_points: [:index, :show]
    }, read: true
    permission :view_psc_schedules, {
      psc_project_schedules: [:index, :show, :calendar],
      psc_schedules: [:index, :show, :calendar]
    }, read: true

    # Manage categories and control points
    permission :manage_psc_categories, {
      psc_categories: [:index, :show, :new, :create, :edit, :update, :destroy, :import, :export],
      psc_control_points: [:index, :show, :new, :create, :edit, :update, :destroy, :generate_schedules, :bulk_generate_schedules],
      psc_project_control_points: [:index, :show, :new, :create, :edit, :update, :destroy, :generate_schedules]
    }

    # Manage schedules
    permission :manage_psc_schedules, {
      psc_project_schedules: [:edit, :update, :generate_issue, :skip, :complete, :reopen, :bulk_generate],
      psc_schedules: [:edit, :update, :generate_issue, :skip, :complete, :reopen, :bulk_generate, :update_overdue]
    }

    # Configure project settings
    permission :configure_psc_settings, {
      psc_settings: [:edit, :update]
    }
  end
end
