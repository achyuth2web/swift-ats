class CreateCalendarIntegrations < ActiveRecord::Migration[7.1]
  def change
    create_table :calendar_integrations do |t|
      t.references :user, null: false, foreign_key: true

      t.string :provider, null: false
      t.string :email
      t.string :calendar_id

      t.text :access_token
      t.text :refresh_token

      t.datetime :token_expires_at

      t.string :sync_token
      t.string :subscription_id
      t.datetime :subscription_expires_at

      t.timestamps
    end

    add_index :calendar_integrations,
              [:user_id, :provider],
              unique: true
  end
end
