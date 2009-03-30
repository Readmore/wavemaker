class ChangeTypeToRecordType < ActiveRecord::Migration
  def self.up
    rename_column :filelists, :type, :record_type
  end

  def self.down
    rename_column :filelists, :record_type, :type
  end
end
