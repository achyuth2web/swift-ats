class CreateNaukriConfigurations < ActiveRecord::Migration[7.1]
  def change
    create_table :naukri_configurations do |t|
      t.string :email, null: false
      t.string :company
      t.boolean :connected, default: false, null: false

      t.timestamps
    end

    add_index :naukri_configurations, :email
  end
end
