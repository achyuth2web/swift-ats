class CreateApplications < ActiveRecord::Migration[7.1]
  def change
    create_table :applications do |t|
      t.references :candidate,
                   null: true,
                   foreign_key: true

      t.references :job,
                   null: true,
                   foreign_key: true

      t.references :assigned_to,
                   null: true,
                   foreign_key: { to_table: :users }

      t.string :status, null: false, default: "open"
      t.string :source
      t.string :source_email

      t.datetime :applied_at
      t.datetime :closed_at

      t.timestamps
    end
  end
end