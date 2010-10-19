class CreateClickedEvents < ActiveRecord::Migration
  def self.up
    create_table :clicked_events do |t|
      t.integer :clicked_url_id
      t.timestamps
    end
  end

  def self.down
    drop_table :clicked_events
  end
end
