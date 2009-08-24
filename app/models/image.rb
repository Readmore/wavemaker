class Image < ActiveRecord::Base
  #belongs_to :card, :foreign_key => "parent_id"

  has_attachment :content_type => :image, 
                  :storage => :file_system, 
                  :max_size => 1024.kilobytes,
                  :thumbnails => { :small => '600x400>', :thumb => '100x100>' }

  validates_as_attachment
  

end



