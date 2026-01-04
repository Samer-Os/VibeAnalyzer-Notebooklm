class AddMissingColumnsToTables < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :name, :string
    add_column :users, :role, :string, default: 'researcher'
    
    add_column :projects, :description, :text
    
    add_column :reports, :title, :string
    add_column :reports, :report_type, :string
    add_column :reports, :metadata, :jsonb
  end
end
