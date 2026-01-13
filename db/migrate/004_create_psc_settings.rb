# frozen_string_literal: true

class CreatePscSettings < ActiveRecord::Migration[5.2]
  def change
    create_table :psc_settings do |t|
      t.references :project, null: false, foreign_key: true
      t.references :default_tracker, foreign_key: { to_table: :trackers }
      t.references :default_priority, foreign_key: { to_table: :enumerations }
      t.string :issue_subject_template, default: '[{{control_id}}] {{control_name}} - {{period}} {{year}}'
      t.text :issue_description_template
      t.integer :advance_days, default: 7
      t.boolean :enable_auto_generation, default: true, null: false
      t.timestamps null: false
    end

    add_index :psc_settings, :project_id, unique: true
  end
end
