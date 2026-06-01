class CreateCandidates < ActiveRecord::Migration[7.1]
  def change
    create_table :candidates do |t|
      t.string  :name,             null: false
      t.string  :email
      t.string  :phone
      t.string  :role
      t.string  :department
      t.string  :designation
      t.string  :skills_list
      t.integer :experience_years, default: 0
      t.string  :status,           default: "New"
      t.integer :score,            default: 0
      t.string  :source
      t.string  :ctc_current
      t.string  :ctc_expected
      t.string  :ctc_unit,         default: "LPA"
      t.string  :notice_period
      t.text    :notes
      t.date    :hire_date
      t.string  :resume_filename
      t.text    :resume_text
      t.references :job,           foreign_key: true
      t.references :recruiter,     foreign_key: { to_table: :users }
      t.timestamps
    end
  end
end
