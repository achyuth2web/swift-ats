class CreateJobStatusHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :job_status_histories do |t|
      t.references :job,  null: false, foreign_key: true
      t.string  :status,  null: false
      t.references :user, foreign_key: true
      t.timestamps
    end
  end
end
