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
  
  def self.find(username, id, pub=false)
    l = Lesson.new(@username)
    l.attributes = GitRecord.find(username, id, pub)
    l.attributes["cards"] = l.attributes["cards"].split(",").each {|str| str.strip!}
    #l.cards = l.cards.split(",").each {|str| str.strip!}
    l
  end
  
  def self.save(username, attributes, pub=false)
    if (cards = attributes["cards"])
      if cards.is_a?(Array)
        attributes["cards"] = cards.join(",")
      end
    end
    
    # CARDS need to be saved as a fully qualified identifier. 
    # that consists of  SHA:path/to/file
    # e.g. "03c0d83cd2e9e1195fb3eb60d6604220fde13da7:#{username}/Cards/bfe057d0-d483-012b-7578-002332ced2f8"
    # this will allow for direct versioning and allow published lessons and courses to have static content
    # to find the current version of a file do this after saving it. 
    # l = repo.log()
    # ver = l.first.sha
    # ver is now the sha of the commit for the current file version. This is what will need to be stored
    # with the referencing objects (Lessons, Cards)
    
    saved = GitRecord.save(username, attributes, pub)
    if saved
      if pub
        # make public cards for all public lessons
          if attributes["cards"].is_a?(Array)
            Lesson.set_cards_public(username, attributes["cards"])
          else
            Lesson.set_cards_public(username, attributes["cards"].split(",").each {|str| str.strip!})
          end
      end
      # get lesson object
      l = Lesson.new(username)
      l.attributes = attributes
      l
    else
      nil
    end
  end
  
  private
  
  def self.set_cards_public(username, cards)
    cards.each do |card_id|
      card = Card.find(username, card_id)
      if card.public == "0"
        card.public = "1"
      end
      Card.save(username, card.attributes, true)
    end
  end

end
