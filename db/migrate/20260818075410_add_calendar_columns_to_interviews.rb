class AddCalendarColumnsToInterviews < ActiveRecord::Migration[7.1]
  def change
    add_column :interviews, :create_calendar_event, :boolean, default: false
    add_column :interviews, :send_calendar_invitation, :boolean, default: false
    add_column :interviews, :meeting_type, :string
    add_column :interviews, :location, :string
  end
end
