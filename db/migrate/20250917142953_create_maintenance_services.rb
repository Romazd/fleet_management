class CreateMaintenanceServices < ActiveRecord::Migration[7.1]
  def change
    create_table :maintenance_services do |t|
      t.references :vehicle, null: false, foreign_key: true
      t.string :description, null: false
      t.integer :status, default: 0, null: false
      t.date :date, null: false
      t.integer :cost_cents, default: 0, null: false
      t.integer :priority, default: 0, null: false
      t.datetime :completed_at

      t.timestamps
    end

    add_index :maintenance_services, :status
    add_index :maintenance_services, :priority
    add_index :maintenance_services, :date
    add_index :maintenance_services, [:vehicle_id, :status]
  end
end
