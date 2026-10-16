class CreateEmailTemplates < ActiveRecord::Migration[7.1]
  def change
    create_table :email_templates do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :subject, null: false
      t.text :body, null: false
      t.boolean :active, null: false, default: true

      t.timestamps
    end

    add_index :email_templates, :slug, unique: true
    add_index :email_templates, :active
  end
end
