class CreateEmailLogs < ActiveRecord::Migration[7.1]
  def change
    create_table :email_logs do |t|
      t.references :user, null: false
      t.references :candidate
      t.string :recipient_email
      t.string :subject
      t.string :template_name
      t.string :status, default: "sent"

      t.timestamps
    end
  end
end
