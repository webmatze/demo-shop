class AddSyncedAtToProducts < ActiveRecord::Migration[8.1]
  def change
    add_column :products, :synced_at, :datetime
  end
end
