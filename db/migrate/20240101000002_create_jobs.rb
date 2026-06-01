class CreateJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :jobs do |t|
      t.string  :title,             null: false
      t.string  :company,           default: "Spritle Software"
      t.string  :department
      t.string  :hiring_manager
      t.string  :position_type,     default: "New"
      t.string  :replacing_employee
      t.integer :openings,          default: 1
      t.string  :status,            default: "Open"
      t.date    :open_date
      t.date    :close_date
      t.date    :reopen_date
      t.date    :hire_date
      t.text    :description
      t.string  :skills_list
      t.integer :experience_years,  default: 0
      t.string  :ctc_budget
      t.string  :naukri_url
      t.timestamps
    end
  end
end
