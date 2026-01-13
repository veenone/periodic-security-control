# frozen_string_literal: true

require 'redmine'

# Load plugin files for Redmine 5.x/6.x compatibility
Rails.application.config.to_prepare do
  require_dependency 'periodic_security_control/hooks'
  require_dependency 'periodic_security_control/issue_patch'

  unless Issue.included_modules.include?(PeriodicSecurityControl::IssuePatch)
    Issue.include(PeriodicSecurityControl::IssuePatch)
  end
end

Redmine::Plugin.register :periodic_security_control do
  name 'Periodic Security Control'
  author 'Security Team'
  description 'Manages periodic security control schedules and auto-generates issues for tracking compliance activities'
  version '1.0.0'
  url 'https://github.com/yourorg/redmine_periodic_security_control'
  author_url 'https://yourorg.com'

  requires_redmine version_or_higher: '5.0.0'

  # Global plugin settings
  settings default: {
    'default_project_id' => nil,
    'issue_author_id' => nil,
    'advance_days' => '7',
    'issue_subject_template' => '[{{control_id}}] {{control_name}} - {{period}} {{year}}',
    'issue_description_template' => "Security Control Check\n\nCategory: {{category}}\nControl: {{control_id}} - {{control_name}}\nPeriod: {{period}} {{year}}\nFrequency: {{frequency}}",
    'enable_auto_generation' => 'true'
  }, partial: 'settings/periodic_security_control_settings'

  # Application menu (global dashboard)
  menu :application_menu, :psc_dashboard,
       { controller: 'psc_dashboard', action: 'index' },
       caption: :label_psc_dashboard,
       if: Proc.new { User.current.logged? && User.current.allowed_to_globally?(:view_psc_dashboard) }

  # Admin menu for managing categories and control points
  menu :admin_menu, :psc_admin,
       { controller: 'psc_categories', action: 'index' },
       caption: :label_psc_admin,
       html: { class: 'icon icon-settings' },
       if: Proc.new { User.current.admin? }

  # Project menu (for project-specific schedule views)
  menu :project_menu, :psc_schedules,
       { controller: 'psc_schedules', action: 'index' },
       caption: :label_psc_schedules,
       after: :activity,
       param: :project_id,
       if: Proc.new { |project|
         project.module_enabled?(:periodic_security_control) &&
         User.current.allowed_to?(:view_psc_schedules, project)
       }

  # Project module definition
  project_module :periodic_security_control do
    # View permissions
    permission :view_psc_dashboard, { psc_dashboard: [:index] }, public: true, read: true
    permission :view_psc_schedules, { psc_schedules: [:index, :show, :calendar] }, read: true

    # Manage permissions
    permission :manage_psc_schedules, {
      psc_schedules: [:edit, :update, :generate_issue, :skip, :complete, :bulk_generate]
    }

    # Admin permissions (requires admin role)
    permission :manage_psc_categories, {
      psc_categories: [:index, :show, :new, :create, :edit, :update, :destroy, :import, :export],
      psc_control_points: [:index, :show, :new, :create, :edit, :update, :destroy, :generate_schedules]
    }, require: :admin

    permission :configure_psc_settings, {
      psc_settings: [:edit, :update]
    }, require: :admin
  end
end
