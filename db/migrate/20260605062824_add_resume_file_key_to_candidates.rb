class AddResumeFileKeyToCandidates < ActiveRecord::Migration[7.1]
  def change
    add_column :candidates, :resume_file_key, :string
  end
end
