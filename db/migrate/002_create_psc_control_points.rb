# frozen_string_literal: true

class CreatePscControlPoints < ActiveRecord::Migration[5.2]
  def change
    create_table :psc_control_points do |t|
      t.references :category, null: false, foreign_key: { to_table: :psc_control_categories, on_delete: :cascade }
      t.string :control_id, null: false
      t.string :name, null: false
      t.text :description
      t.string :frequency, null: false, default: 'monthly'
      t.integer :position, default: 1
      t.boolean :active, default: true, null: false
      t.references :tracker, foreign_key: true
      t.references :priority, foreign_key: { to_table: :enumerations }
      t.references :assigned_to, foreign_key: { to_table: :users }
      t.timestamps null: false
    end

    add_index :psc_control_points, :control_id, unique: true
    add_index :psc_control_points, [:category_id, :position]
    add_index :psc_control_points, :frequency
    add_index :psc_control_points, :active
  end
end
