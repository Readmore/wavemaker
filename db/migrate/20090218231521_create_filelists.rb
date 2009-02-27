class CreateFilelists < ActiveRecord::Migration
  def self.up
    create_table :filelists do |t|
      t.column :path, :string
      t.column :version, :integer
      t.column :repo, :string
      t.column :type, :string
      t.column :author, :string
      t.column :current, :boolean
      t.timestamps
    end
    
    add_index :filelists, [:repo, :type], :name => "file_repo_type_indx"
  end

  def self.down
    remove_index :filelists, :name => "file_repo_type_indx"
    drop_table :filelists
  end
end
