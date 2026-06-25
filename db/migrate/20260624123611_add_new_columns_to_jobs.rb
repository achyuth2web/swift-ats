class AddNewColumnsToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :job_type, :string, default: "Full-Time"
    add_column :jobs, :stipend, :string
  end
end
