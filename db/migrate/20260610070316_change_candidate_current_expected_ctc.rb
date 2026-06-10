class ChangeCandidateCurrentExpectedCtc < ActiveRecord::Migration[7.1]
  def up
    execute <<~SQL
      UPDATE candidates
      SET ctc_current = NULL
      WHERE ctc_current !~ '^[0-9]+(\.[0-9]+)?$';
    SQL

    execute <<~SQL
      UPDATE candidates
      SET ctc_expected = NULL
      WHERE ctc_expected !~ '^[0-9]+(\.[0-9]+)?$';
    SQL

    change_column :candidates,
                  :ctc_current,
                  'decimal(10,2) USING ctc_current::decimal'

    change_column :candidates,
                  :ctc_expected,
                  'decimal(10,2) USING ctc_expected::decimal'
  end

  def down
    change_column :candidates, :ctc_current, :string
    change_column :candidates, :ctc_expected, :string
  end
end