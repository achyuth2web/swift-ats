class AddNewColumnsToInterviews < ActiveRecord::Migration[7.1]
  def change
    change_column_default :interviews, :round_number, from: 1, to: nil
    change_column :interviews, :round_number, :string, using: 'round_number::text'
    add_column :interviews, :mode_of_interview, :string
  end
end
