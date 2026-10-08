class CreateGmailIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :gmail_integrations do |t|
      t.string :email, null: false
      t.text :access_token
      t.text :refresh_token
      t.datetime :token_expires_at

      t.timestamps
    end

    add_index :gmail_integrations, :email, unique: true
  end
end
