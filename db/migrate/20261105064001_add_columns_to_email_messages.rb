class AddColumnsToEmailMessages < ActiveRecord::Migration[7.1]
  def change
    add_reference :email_messages,
                  :assigned_to,
                  foreign_key: { to_table: :users },
                  index: true,
                  null: true

    add_column :email_messages, :application_status, :string
    add_column :email_messages, :processed_at, :datetime

    add_index :email_messages, :application_status
  end
end
