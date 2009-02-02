class Course < GitRecord
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
      "lessons"       => [],
      "created_at"  => Time.now.strftime('%Y/%m/%d'),
      "public"      => "0",
      "type"        => "course",
      "lesson_type" => ""
      
    }
  end
  
  def on_update
    if (tags = @attributes["tags"]) && tags.is_a?(Array)
      @attributes["tags"] = tags.join(",")
    end
    
    if (lessons = @atributes["lessons"]) 
      if lessons.is_a?(Array)
        # make public lessons for all public courses
        if @attributes["public"] == "1"
          set_lessons_public(@attributes["lessons"])
        end
        @attributes["lessons"] = lessons.join(",")
      else
        # make public lessons for all public courses
        if @attributes["public"] == "1"
          set_lessons_public(@attributes["lessons"].split(","))
        end
      end
    end
  end
  
  def self.find(username, id, pub=false)
    l = Course.new(@username)
    l.attributes = GitRecord.find(username, id, pub)
    l.lessons = l.lessons.split(",").each {|str| str.strip!}
    l
  end
  
  def self.save(username, attributes, pub=false)
    saved = GitRecord.save(username, attributes, pub)
    if saved
      l = Course.new(username)
      l.attributes = attributes
      l
    else
      nil
    end
  end

  private
  
  def set_lessons_public(lessons)
    lessons.each do |lesson_id|
      lesson = Lesson.find(@user.login, lesson_id)
      if lesson.public != "1"
        lesson.public = "1"
        lesson.save(@user.login, lesson.attributes, true)
      end
    end
  end
  
end
