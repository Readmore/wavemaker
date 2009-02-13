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
    
    if (authors = @attributes["author"] && authors.is_a?(Array))
      @attributes["author"] = authors.join(",")
    end
  end
  
  def self.find(username, id, version="HEAD", pub=false)
    c = Card.new(username)
    h = GitRecord.find_by_version(username, id, version, pub)
    if h.empty?
      h = GitRecord.find_by_version("master", id, version, pub)
    end
    h["author"] = h["author"].split(",")
    c.attributes = h 
    c
  end
  
  def self.clone(username, id, version="HEAD")
    # Get Card from master
    card = Card.find("master", id, version)
    
    if card && !card.author.include?(username)
      # Update Author fieldd
      if card.author.is_a?(Array)
        authors = card.author.insert(0, username)
        card.author = authors.join(",")
      else
        card.author = username + "," + card.author
      end
      # Save Card to user's repo
      Card.save(username, card.attributes)
      return true
    end
    
    return false
  end
  
  def self.save(username, attrs, pub=false)
    if attrs["author"] && !attrs["author"].include?(username)
      #add this user's name
      authors = attrs["author"].insert(0, username)
    end
    attrs["author"] = attrs["author"].join(",")
    
    commit = GitRecord.save(username, attrs, pub)
    if commit
      c = Card.new(username)
      c.attributes = attrs
      c.attributes["commit"] = commit
      c
    else
      nil
    end
  end
  #Possibly add a find method that calls Super.find 
  #and then changes tags back into an array on the return
  
end
