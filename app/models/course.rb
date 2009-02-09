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
  
  def self.find(username, id, version="HEAD")
    c = Course.new(@username)
    c.attributes = GitRecord.find_by_version(username, id, version)
    c.lessons = c.lessons.split(",").each {|str| str.strip!}
    c.author = c.author.split(",")
    c
  end
  
  def self.clone(username, id, version="HEAD")
    # Get Course from master
    course = Course.find("master", id, version)
    
    if course && !course.author.include?(username)
      # Update Author fieldd
      if course.author.is_a?(Array)
        authors = course.author.insert(0, username)
        course.author = authors.join(",")
      else
        course.author = username + "," + course.author
      end
      
      # Clone the lessons referenced by this course
      Course.clone_lessons(username, course.lessons)
      
      # Save Course to user's repo
      Course.save(username, course.attributes)
      return true
    end
    
    return false
  end
  
  def self.save(username, attributes, pub=false)
    
    # LESSONS need to be saved as a fully qualified identifier. 
    # that consists of  SHA:path/to/file
    # e.g. "03c0d83cd2e9e1195fb3eb60d6604220fde13da7:#{username}/Lesson/bfe057d0-d483-012b-7578-002332ced2f8"
    # this will allow for direct versioning and allow published lessons and courses to have static content
    if pub
      # make public lessons for all public courses
       attributes["lessons"] = Course.set_lessons_public(username, attributes["lessons"].split(",").each {|str| str.strip!})
    end
    saved = GitRecord.save(username, attributes, pub)
    if saved
      l = Course.new(username)
      l.attributes = attributes
      l.attributes["commit"] = saved
      l
    else
      nil
    end
  end

  private
  
  def self.clone_lessons(username, lessons)
    # split out the version from the id in the lessons array
    # then call clone for each lesson with the correct version
    lessons.each do |id|
      res = id.split(":")
      version = "HEAD"
      if res[1]
        version = res[0]
        id = res[1]
      end
      Lesson.clone(username, id, version)
    end
  end
  
  def self.set_lessons_public(username, lessons)
    lessons_arr = []
    lessons.each do |lesson_id|
      version = "HEAD"
      res = lesson_id.split(":")
      if res[1]
        version = res[0]
        lesson_id = res[1]
      end
      lesson = Lesson.find(username, lesson_id, version)
      
      if lesson.public == "0"
        lesson.public = "1"
      end
      l = Lesson.save(username, lesson.attributes, true)
      if l && l.commit
        lessons_arr << "#{l.commit}:#{l._id}"
      else
        lessons_arr << "HEAD:#{l._id}"
      end
    end
    lessons_arr.join(",")
  end
  
end
