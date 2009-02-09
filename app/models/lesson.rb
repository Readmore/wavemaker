class Lesson < GitRecord
  
  def initialize(username)
    @username = username
    @attributes = default_attributes
  end
  
  def attributes
    @attributes
  end
  
  def default_attributes
    {
      "_id"         => $uuid.generate,
      "_rev"        => "0",
      "author"      => @username, # @user.login,
      "title"       => "",
      "body"        => "",
      "tags"        => [],
      "cards"       => [],
      "created_at"  => Time.now.strftime('%Y/%m/%d'),
      "public"      => "0",
      "type"        => "lesson",
      "lesson_type" => ""
      
    }
  end
  
  def on_update
    if (tags = @attributes["tags"]) && tags.is_a?(Array)
      @attributes["tags"] = tags.join(",")
    end
    
    if (cards = @attributes["cards"])
      if cards.is_a?(Array)
        @attributes["cards"] = cards.join(",")
      end
    end
  end
  
  def self.find(username, id, version="HEAD", pub=false)
    l = Lesson.new(username)
    l.attributes = GitRecord.find_by_version(username, id, version, pub)
    if !l.attributes.empty?
      l.attributes["cards"] = l.attributes["cards"].split(",").each {|str| str.strip!}
      #l.cards = l.cards.split(",").each {|str| str.strip!}
    end
    l.attributes["author"] = l.attributes["author"].split(",")
    l
  end
  
  def self.clone(username, id, version="HEAD")
    # Get Lesson from master
    lesson = Lesson.find("master", id, version)
    
    if lesson && !lesson.author.include?(username)
      # Update Author fieldd
      if lesson.author.is_a?(Array)
        authors = lesson.author.insert(0, username)
        lesson.author = authors.join(",")
      else
        lesson.author = username + "," + lesson.author
      end
      
      # Clone the cards referenced by this lesson
      Lesson.clone_cards(username, lesson.cards)
      
      # Save Lesson to user's repo
      Lesson.save(username, lesson.attributes)
      return true
    end
    
    return false
  end
  
  def self.save(username, attributes, pub=false)
    if (cards = attributes["cards"])
      if cards.is_a?(Array)
        attributes["cards"] = cards.join(",")
      end
    end
    
    # CARDS need to be listed as a fully qualified identifier. 
    # that consists of  SHA:file_id
    # e.g. "03c0d83cd2e9e1195fb3eb60d6604220fde13da7:bfe057d0-d483-012b-7578-002332ced2f8"
    # this will allow for direct versioning and allow published lessons and courses to have static content
    # to find the current version of a file do this after saving it. 
    # res = repo.grep("_id => #{file_id}")
    # ver = res.split(":")
    # ver[0] is the commit sha
    # ver is now the sha of the commit for the current file version. This is what will need to be stored
    # with the referencing objects (Lessons, Cards)
    
    # If you want to keep the private lessons always pointing to the latest cards
    # save the lesson here with username, then do you pub check and if it's true 
    # calc your commit ids and save again with master
    
    if pub
      # make public cards for all public lessons
        if attributes["cards"].is_a?(Array)
          attributes["cards"] = Lesson.set_cards_public(username, attributes["cards"])
        else
          attributes["cards"] = Lesson.set_cards_public(username, attributes["cards"].split(",").each {|str| str.strip!})
        end
    end
    commit = GitRecord.save(username, attributes, pub)
    if commit
      # get lesson object
      l = Lesson.new(username)
      l.attributes = attributes
      l.attributes["commit"] = commit 
      l
    else
      nil
    end
  end
  
  private
  
  def self.clone_cards(username, cards)
    # split out the version from the id in the cards arra
    # then call clone for each card with the correct version
    cards.each do |id|
      res = id.split(":")
      version = "HEAD"
      if res[1]
        version = res[0]
        id = res[1]
      end
      Card.clone(username, id, version)
    end
  end
  
  def self.set_cards_public(username, cards)
    cards_arr = []
    cards.each do |card_id|
      version = "HEAD"
      res = card_id.split(":")
      if res[1] 
        version = res[0]
        card_id = res[1]
      end
      card = Card.find(username, card_id, version)
    
      if card.public == "0"
        card.public = "1"
      end
      c = Card.save(username, card.attributes, true)
      if c && c.commit
        cards_arr << "#{c.commit}:#{c._id}"
      else
        cards_arr << "HEAD:#{c._id}"
      end
    end
    cards_arr.join(",")
  end

  # l = repo.log()
  # ver = l.first.sha

end
