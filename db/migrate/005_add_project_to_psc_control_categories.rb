# frozen_string_literal: true

class AddProjectToPscControlCategories < ActiveRecord::Migration[5.2]
  def change
    unless column_exists?(:psc_control_categories, :project_id)
      add_reference :psc_control_categories, :project, type: :integer, null: true, foreign_key: true
      add_index :psc_control_categories, [:project_id, :code], unique: true, name: 'idx_psc_categories_project_code'
    end

    # Update uniqueness: code should be unique per project, not globally
    # Remove the old global unique index on code if it exists
    if index_exists?(:psc_control_categories, :code, unique: true)
      remove_index :psc_control_categories, :code
      add_index :psc_control_categories, :code, name: 'index_psc_control_categories_on_code'
    end
  end
end
