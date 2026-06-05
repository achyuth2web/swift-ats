class AddDiscardedAtToJobs < ActiveRecord::Migration[7.1]
  def change
    add_column :jobs, :discarded_at, :datetime
    add_index :jobs, :discarded_at
  end
end
