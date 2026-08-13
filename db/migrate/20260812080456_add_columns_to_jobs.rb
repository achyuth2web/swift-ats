class AddColumnsToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :closing_notes, :text
    add_column :jobs, :onhold_notes, :text
    add_column :jobs, :interview_type, :string
    change_column :jobs, :experience_years, :string, using: 'experience_years::text'
  end
end
