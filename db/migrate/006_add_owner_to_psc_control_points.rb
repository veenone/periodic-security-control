# frozen_string_literal: true

class AddOwnerToPscControlPoints < ActiveRecord::Migration[5.2]
  def change
    unless column_exists?(:psc_control_points, :owner_id)
      add_reference :psc_control_points, :owner, type: :integer, foreign_key: { to_table: :users }
      add_index :psc_control_points, :owner_id unless index_exists?(:psc_control_points, :owner_id)
    end
  end
end
