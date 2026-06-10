class ChangeJobCtcBudget < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE jobs
      SET ctc_budget = NULL
      WHERE ctc_budget !~ '^[0-9]+(\.[0-9]+)?$';
    SQL

    change_column :jobs,
                  :ctc_budget,
                  'decimal(10,2) USING ctc_budget::decimal'
  end

  def down
    change_column :jobs, :ctc_budget, :string
  end
end