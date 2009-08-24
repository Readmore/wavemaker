class CreateImages < ActiveRecord::Migration
  def self.up
    create_table :images do |t|
      t.column :parent_id,    :integer
      t.column :content_type, :string
      t.column :filename,     :string
      t.column :thumbnail,    :string
      t.column :size,         :integer
      t.column :width,        :integer
      t.column :height,       :integer
      t.timestamps
    end
    add_index :images, :parent_id, :name => "image_parent_indx"
  end

  def self.down
    remove_index :images, :name => "image_parent_indx"
    drop_table :images
  end
end