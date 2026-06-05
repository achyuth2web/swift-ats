class AddDiscardedAtToInterviews < ActiveRecord::Migration[7.1]
  def change
    add_column :interviews, :discarded_at, :datetime
    add_index :interviews, :discarded_at
  end
end
