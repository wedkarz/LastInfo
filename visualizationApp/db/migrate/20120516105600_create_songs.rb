class CreateSongs < ActiveRecord::Migration
  def change
    create_table :songs do |t|
      t.string :artist
      t.integer :duration
      t.string :name
      t.string :country
      t.string :id
      t.integer :rank
      t.integer :listeners

      t.timestamps
    end
  end
end
