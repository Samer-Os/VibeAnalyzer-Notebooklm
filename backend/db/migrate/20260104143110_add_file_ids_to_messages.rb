class AddFileIdsToMessages < ActiveRecord::Migration[8.1]
  def change
    add_column :messages, :file_ids, :jsonb
  end
end
