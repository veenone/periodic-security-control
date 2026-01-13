# frozen_string_literal: true

module PeriodicSecurityControl
  class Hooks < Redmine::Hook::ViewListener
    # Show PSC information on issue show page
    render_on :view_issues_show_details_bottom, partial: 'hooks/view_issues_show_details'

    # Add PSC summary to project overview sidebar
    render_on :view_projects_show_sidebar_bottom, partial: 'hooks/view_projects_show_sidebar'

    # Add link in issue context menu (optional)
    def view_issues_context_menu_end(context = {})
      # Could add context menu items here if needed
    end

    # Called when an issue is created
    def controller_issues_new_after_save(context = {})
      # Could add logic here if needed when issues are created
    end

    # Called when an issue is updated
    def controller_issues_edit_after_save(context = {})
      # The issue patch handles status sync automatically
    end
  end
end
