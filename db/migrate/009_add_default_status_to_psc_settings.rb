# frozen_string_literal: true

class AddDefaultStatusToPscSettings < ActiveRecord::Migration[5.2]
  def change
    add_column :psc_settings, :default_status_id, :integer unless column_exists?(:psc_settings, :default_status_id)
  end
end
