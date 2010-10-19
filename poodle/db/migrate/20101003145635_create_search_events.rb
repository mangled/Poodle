class CreateSearchEvents < ActiveRecord::Migration
  def self.up
    create_table :search_events do |t|
      # For now we just record a search instance, at some point we will also
      # record what was searched for - This record will then be extended
      t.timestamps
    end
  end

  def self.down
    drop_table :search_events
  end
end
