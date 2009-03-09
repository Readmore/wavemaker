class AddTitleToFilelist < ActiveRecord::Migration
  def self.up
    add_column :filelists, :title, :string
  end

  def self.down
    remove_column :filelists, :title
  end
end
