# frozen_string_literal: true

class ChangeControlIdUniquenessToCategoryScope < ActiveRecord::Migration[5.2]
  def change
    # Remove old unique index on control_id alone
    remove_index :psc_control_points, :control_id, if_exists: true

    # Add new composite unique index scoped to category
    unless index_exists?(:psc_control_points, [:category_id, :control_id], name: 'idx_psc_control_points_category_control')
      add_index :psc_control_points, [:category_id, :control_id],
                unique: true,
                name: 'idx_psc_control_points_category_control'
    end
  end
end
