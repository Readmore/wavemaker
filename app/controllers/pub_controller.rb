class PubController < ApplicationController
  # outside basic html view for public education information
  
  def index
    # show all public info, sorted by most recent
    
  end
  
  def lesson
    # show a specific lesson
    @branch = "master"
    @version = "HEAD"

    if params[:version]
      @version = params[:version]
      @lesson = Lesson.find(@branch, params[:id], "HEAD")  #params[:version])
    else
      @lesson = Lesson.find(@branch, params[:id])
    end
    
    if params[:course]
      @course = Course.find(@branch, params[:course]) 
    end
    @cards = []
    
    if !@lesson.attributes.empty? && @lesson.cards
      num = @lesson.cards.length
      #parse lesson.post and find and card identifiers [fc:x] where x is the array index
      @identifiers = num.times.map {|x| "[fc:#{x}]"}
      @cards = @lesson.cards.map do |card_id| 
        #determine if there are any versions stored with these card_ids
        version = "HEAD"
        res = card_id.split(":")
        if res[1] 
          version = res[0]
          card_id = res[1]
        end
        if params[:pub]
          Card.find(@branch, card_id, "HEAD", true) #was version not HEAD
        else
          Card.find(@branch, card_id)
        end
        
      end
      @identifiers.each_with_index do |idf, ndx|
          @lesson.post.gsub!(idf, "")
      end
    end
    
  end
  
  def course
    # show a specific course
    if params[:id]
        @branch = "master"
        @version = "HEAD"

        @course = Course.find(@branch, params[:id])
        if @course
          num = @course.lessons.length
          #parse course.post and find all lesson identifiers [fc:x] where x is the array index
          #@identifiers = num.times.map {|x| "[fl:#{x}]"}
          #@lessons = @course.lessons.map { |lesson_id| Lesson.find(branch, lesson_id)}

           @lessons = @course.lessons.map do |lesson_id| 
              #determine if there are any versions stored with these card_ids
              version = "HEAD"
              res = lesson_id.split(":")
              if res[1] 
                version = res[0]
                lesson_id = res[1]
              end
              if params[:pub]
                Lesson.find(@branch, lesson_id, "HEAD", true) #was version not HEAD
              else
                Lesson.find(@branch, lesson_id)
              end
            end


          #each time an identifier is found pull that lesson object from the array and insert 
            # the lesson information with a link to view it....
          #save this page to lesson post and the cards will render inline with the lesson
          #@identifiers.each_with_index do |idf, ndx|
          #    @course.post.gsub!(idf, lesson_display(@lessons[ndx]))
          #end 
        end
    end
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @course}
    end
    
  end
  
  def card
    # show a specific card
    
  end

end
