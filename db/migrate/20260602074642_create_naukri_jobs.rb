class CreateNaukriJobs < ActiveRecord::Migration[7.1]
  def change
    create_table :naukri_jobs do |t|
      t.references :naukri_configuration,
                   null: false,
                   foreign_key: true

      t.references :job,
                   null: true,
                   foreign_key: true

      t.string :title, null: false
      t.string :location
      t.string :external_id
      t.date :posted_on
      t.string :url
      t.text :notes

      t.timestamps
    end

    add_index :naukri_jobs, :external_id
    add_index :naukri_jobs, :title
  end
end
