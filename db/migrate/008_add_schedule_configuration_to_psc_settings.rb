# frozen_string_literal: true

class AddScheduleConfigurationToPscSettings < ActiveRecord::Migration[5.2]
  def change
    # Weekly: which day to start (1=Monday, 5=Friday)
    add_column :psc_settings, :weekly_start_day, :integer, default: 1 unless column_exists?(:psc_settings, :weekly_start_day)

    # Monthly: which day of month to start (1-28)
    add_column :psc_settings, :monthly_start_day, :integer, default: 1 unless column_exists?(:psc_settings, :monthly_start_day)

    # Quarterly: which month to start quarters (1=Jan, 4=Apr, etc.)
    add_column :psc_settings, :quarterly_start_month, :integer, default: 1 unless column_exists?(:psc_settings, :quarterly_start_month)

    # Six monthly: which month to start semi-annual periods (1=Jan, 7=Jul)
    add_column :psc_settings, :six_monthly_start_month, :integer, default: 1 unless column_exists?(:psc_settings, :six_monthly_start_month)

    # Yearly: which month to start the year (1=Jan for calendar year, 4=Apr for fiscal)
    add_column :psc_settings, :yearly_start_month, :integer, default: 1 unless column_exists?(:psc_settings, :yearly_start_month)
  end
end
