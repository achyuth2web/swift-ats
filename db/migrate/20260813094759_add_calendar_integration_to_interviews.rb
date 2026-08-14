class AddCalendarIntegrationToInterviews < ActiveRecord::Migration[7.1]
  def change
    add_reference :interviews, :calendar_integration, foreign_key: true

    add_column :interviews, :calendar_provider, :string
    add_column :interviews, :external_event_id, :string
    add_column :interviews, :calendar_id, :string
    add_column :interviews, :meeting_url, :string
    add_column :interviews, :calendar_sync_status, :string

    add_index :interviews,
              [:calendar_provider, :external_event_id],
              unique: true
  end
end
