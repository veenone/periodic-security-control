# frozen_string_literal: true

module PscDashboardHelper
  def psc_status_class(status)
    case status
    when 'completed' then 'psc-status-completed'
    when 'overdue' then 'psc-status-overdue'
    when 'generated' then 'psc-status-generated'
    when 'skipped' then 'psc-status-skipped'
    else 'psc-status-pending'
    end
  end

  def psc_completion_bar(completed, total)
    return 0 if total.zero?

    ((completed.to_f / total) * 100).round(0)
  end

  def psc_days_label(days)
    if days.nil?
      '-'
    elsif days == 1
      "1 #{l(:label_day)}"
    else
      "#{days} #{l(:label_days)}"
    end
  end
end
