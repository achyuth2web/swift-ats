class AddNewColumnsToCandidates < ActiveRecord::Migration[7.1]
  def change
    add_column :candidates, :referral_type, :string
    add_column :candidates, :employee_name, :string
    add_column :candidates, :employee_code, :string
    add_column :candidates, :employee_company, :string
    add_column :candidates, :other_referrals, :string
    change_column :candidates, :experience_years, :string, using: 'experience_years::text'
  end
end
