class CreateCandidateStatusHistories < ActiveRecord::Migration[7.1]
  def change
    create_table :candidate_status_histories do |t|
      t.references :candidate, null: false, foreign_key: true
      t.string  :status,       null: false
      t.string  :note
      t.references :user,      foreign_key: true
      t.timestamps
    end
  end
end
