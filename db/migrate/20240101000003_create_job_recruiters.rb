class CreateJobRecruiters < ActiveRecord::Migration[7.1]
  def change
    create_table :job_recruiters do |t|
      t.references :job,  null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.timestamps
    end
    add_index :job_recruiters, [:job_id, :user_id], unique: true
  end
end
