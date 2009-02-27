class CreateWordlocs < ActiveRecord::Migration
  def self.up
    create_table :wordlocs do |t|
      t.column :file_id, :integer
      t.column :word_id, :integer
      t.column :location, :integer
      t.timestamps
    end
  
    add_index :wordlocs, :word_id, :name => "word_file_indx"
  end

  def self.down
    remove_index :word_locs, :name => "word_file_indx"
    drop_table :wordlocs
  end
end
