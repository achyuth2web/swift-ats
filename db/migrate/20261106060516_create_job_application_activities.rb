class CreateJobApplicationActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :job_application_activities do |t|
      t.references :email_message, null: false, foreign_key: true

      t.references :actor,
                   null: false,
                   foreign_key: { to_table: :users }

      t.string :action, null: false
      t.integer :from_user_id
      t.integer :to_user_id
      t.jsonb :details, null: false, default: {}

      t.timestamps
    end

    add_index :job_application_activities, :from_user_id
    add_index :job_application_activities, :to_user_id
  end
end
