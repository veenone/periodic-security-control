# frozen_string_literal: true

class CreatePscSchedules < ActiveRecord::Migration[5.2]
  def change
    unless table_exists?(:psc_schedules)
      create_table :psc_schedules do |t|
        t.references :control_point, null: false, foreign_key: { to_table: :psc_control_points, on_delete: :cascade }
        t.integer :year, null: false
        t.integer :period_number, null: false
        t.date :scheduled_date, null: false
        t.date :due_date
        t.references :issue, type: :integer, foreign_key: true
        t.string :status, null: false, default: 'pending'
        t.datetime :generated_at
        t.datetime :completed_at
        t.text :notes
        t.timestamps null: false
      end
    end

    add_index :psc_schedules, [:control_point_id, :year, :period_number],
              unique: true, name: 'idx_psc_schedules_unique_period' unless index_exists?(:psc_schedules, [:control_point_id, :year, :period_number], name: 'idx_psc_schedules_unique_period')
    add_index :psc_schedules, :scheduled_date unless index_exists?(:psc_schedules, :scheduled_date)
    add_index :psc_schedules, :due_date unless index_exists?(:psc_schedules, :due_date)
    add_index :psc_schedules, :status unless index_exists?(:psc_schedules, :status)
    add_index :psc_schedules, [:year, :status] unless index_exists?(:psc_schedules, [:year, :status])
    # Note: issue_id index is automatically created by t.references
  end
end
