class CreateJobOpenings < ActiveRecord::Migration[7.1]
  def change
    create_table :job_openings do |t|
      t.references  :job,
                    null: true,
                    foreign_key: true
      t.integer     :sequence_no
      t.date        :closed_date
      t.date        :onboarded_date


      t.timestamps
    end
  end
end
