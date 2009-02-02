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
    #l.attributes["cards"] = l.attributes["cards"].split(",").each {|str| str.strip!}
    l.cards = l.cards.split(",").each {|str| str.strip!}
    l
  end
  
  def self.save(username, attributes, pub=false)
    saved = GitRecord.save(username, attributes, pub)
    if pub
      # make public cards for all public lessons
        Lesson.set_cards_public(username, attributes["cards"].split(",").each {|str| str.strip!})
    end
    if saved
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
        puts "Saving Card as Public in Set Cards Public!"
        card.save(username, card.attributes, true)
      end
    end
  end

end
