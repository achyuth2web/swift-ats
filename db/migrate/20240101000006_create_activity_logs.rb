class CreateActivityLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :activity_logs do |t|
      t.string  :message, null: false
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
