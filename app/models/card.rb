class Card < GitRecord
  
  def initialize(username)
    @username = username
    @attributes = default_attributes
  end
  
  def attributes
    @attributes
  end
  
  def default_attributes
    #@user = User.find_by_id(session[:user_id])
    {
      "_id"        => $uuid.generate,
      "_rev"       => "0",
      "author"     => @username, # @user.login,
      "title"      => "",
      "body"       => "",
      "tags"       => [],
      "created_at" => Time.now.strftime('%Y/%m/%d'),
      "public"     => "0",
      "type"       => "card",
      "card_type"  => ""
      
    }
  end
  
  def on_update
    if (tags = @attributes["tags"]) && tags.is_a?(Array)
      @attributes["tags"] = tags.join(",")
    end
  end
  
  def self.find(username, id, pub=false)
    c = Card.new(@username)
    h = GitRecord.find(username, id, pub)
    if h.empty?
      h = GitRecord.find("master", id, pub)
    end
    c.attributes = h 
    c
  end
  
  def self.save(username, attrs, pub=false)
    saved = GitRecord.save(username, attrs, pub)
    if saved
      c = Card.new(username)
      c.attributes = attrs
      c
    else
      nil
    end
  end
  #Possibly add a find method that calls Super.find 
  #and then changes tags back into an array on the return
  
end
