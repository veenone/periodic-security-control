# frozen_string_literal: true

class CreatePscControlCategories < ActiveRecord::Migration[5.2]
  def change
    create_table :psc_control_categories do |t|
      t.string :name, null: false
      t.string :code, null: false, limit: 5
      t.text :description
      t.integer :position, default: 1
      t.boolean :active, default: true, null: false
      t.timestamps null: false
    end

    add_index :psc_control_categories, :code, unique: true
    add_index :psc_control_categories, :position
    add_index :psc_control_categories, :active
  end
end
