class AddFieldsToEmailLogs < ActiveRecord::Migration[7.1]
  def change
    add_column :email_logs, :cc_email, :string
    add_column :email_logs, :body, :text
    add_column :email_logs, :error_message, :string
    change_column_default :email_logs, :status, from: "sent", to: "pending"
  end
end
