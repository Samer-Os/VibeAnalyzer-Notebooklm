class CreateMessages < ActiveRecord::Migration[8.1]
  def change
    create_table :messages do |t|
      t.text :content
      t.string :role
      t.references :project, null: false, foreign_key: true
      t.string :container_id

      t.timestamps
    end
  end
end
