class AddNewColumnsToCalendarIntegrations < ActiveRecord::Migration[7.1]
  def change
    add_column :calendar_integrations, :google_channel_id, :string
    add_column :calendar_integrations, :google_resource_id, :string
    add_column :calendar_integrations, :google_channel_expires_at, :datetime

    add_index :calendar_integrations, :google_channel_id, unique: true
    add_index :calendar_integrations, :google_resource_id
  end
end
