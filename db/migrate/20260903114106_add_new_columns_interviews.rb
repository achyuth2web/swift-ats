class AddNewColumnsInterviews < ActiveRecord::Migration[7.1]
  def change
    add_column :interviews, :meet_link, :string
    add_column :interviews, :resume_drive_file_id, :string

    add_index :interviews, :resume_drive_file_id
  end
end
