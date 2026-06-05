class AddDiscardedAtToCandidates < ActiveRecord::Migration[7.1]
  def change
    add_column :candidates, :discarded_at, :datetime
    add_index :candidates, :discarded_at
  end
end
