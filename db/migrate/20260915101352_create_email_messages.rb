class CreateEmailMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :email_messages do |t|
      t.references :application,
                   null: true,
                   foreign_key: true

      t.references :candidate,
                   null: true,
                   foreign_key: true

      t.string :message_id, null: false
      t.string :thread_id

      t.string :direction, null: false
      t.string :status, null: false, default: "received"

      t.string :from_email, null: false
      t.text :to_emails
      t.text :cc_emails

      t.string :subject
      t.text :body
      t.text :snippet

      t.string :mailbox
      t.datetime :received_at
      t.datetime :sent_at

      t.jsonb :headers, null: false, default: {}
      t.jsonb :metadata, null: false, default: {}

      t.timestamps
    end

    add_index :email_messages, :message_id, unique: true
    add_index :email_messages, :thread_id
    add_index :email_messages, :from_email
    add_index :email_messages, :mailbox
  end
end