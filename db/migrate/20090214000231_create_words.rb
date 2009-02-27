class CreateWords < ActiveRecord::Migration
  def self.up
    create_table :words do |t|
      t.column :word, :string
      t.timestamps
    end
    
    add_index :words, :word, :name => 'word_indx'
  end

  def self.down
    remove_index :words, :name => :word_indx
    
    drop_table :words
  end
end