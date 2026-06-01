class CreateInterviews < ActiveRecord::Migration[7.1]
  def change
    create_table :interviews do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string  :round_name,   null: false
      t.integer :round_number, default: 1
      t.string  :interviewer
      t.datetime :scheduled_at
      t.string  :status,       default: "Scheduled"
      t.string  :outcome
      t.text    :feedback
      t.integer :rating
      t.timestamps
    end
  end
end
