class CreateUrls < ActiveRecord::Migration
  def self.up
    create_table :urls do |t|
      t.string :url
      t.integer :click_count
      t.timestamps
    end
  end

  def self.down
    drop_table :urls
  end
end
