class UiController < ApplicationController
  before_filter :login_required, :find_user
  
  def home
    @pics = ["futureofnet.jpg", "tcc-women-studies.jpg", "mit-programming-1.jpg", "cell-programming-1.jpg", "mit-math-1.jpg"]
    #@public_cards = Card.view("master", "cards_by_public")
    
    @public_courses = Course.view("master", "courses_by_public")
  end
  
  def search
   @searcher = Searcher.new
    @results = []
    if params[:q] 
      #search the index for this query
      query = params[:q]
    elsif params[:search]
      query = params[:search][:q]
    end
    if query
      if @user
        @results = @searcher.search(query, [@user.login, "master"])  
      else
        @results = @searcher.search(query) 
      end
    end
  end
  
  def course_view
    if params[:id]
        @branch = "master"
        @version = "HEAD"
        
        if @user && !params[:pub]
          @branch = @user.login
        end

        @course = Course.find(@branch, params[:id])
        if @course
          num = @course.lessons.length
          #parse course.post and find all lesson identifiers [fc:x] where x is the array index
          @identifiers = num.times.map {|x| "[fl:#{x}]"}
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
          @identifiers.each_with_index do |idf, ndx|
              @course.post.gsub!(idf, lesson_display(@lessons[ndx]))
          end 
        end
    end
  end
  
  def lesson_view
    @branch = "master"
    @version = "HEAD"

    if @user && !params[:pub]
      @branch = @user.login
    end

    if params[:version]
      @version = params[:version]
      @lesson = Lesson.find(@branch, params[:id], "HEAD")  #params[:version])
    else
      @lesson = Lesson.find(@branch, params[:id])
    end
    
    if params[:course]
      @course = Course.find(@branch, params[:course]) 
    end

    if !@lesson.attributes.empty? 
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

      #each time an identifier is found pull that card object from the array and insert 
        # the correct html for the card....
      #save this page to lesson post and the cards will render inline with the lesson
      @identifiers.each_with_index do |idf, ndx|
          @lesson.post.gsub!(idf, card_display(@cards[ndx]))
      end 
    end

  end
  
  def card_view
    @branch = "master"
    @version = "HEAD"
    
    if @user && !params[:pub]
      @branch = @user.login
    end
    
    #@card = Card.new(@user.login)
    if params[:version]
      @version = params[:version]
      @card = Card.find(@branch, params[:id], params[:version])
    else
      @card = Card.find(@branch, params[:id])
    end
  end
  
  def my_data
    #show the user's courses
     if @user
        @my_courses = Course.view(@user.login, "courses_by_author", {:author => @user.login})
      end
  end
  
  def public_data 
    @public_courses = Course.view("master", "courses_by_public")
  end
  
  private

  def lesson_display(lesson)
      render_to_string :partial => "courses/display_lesson_card", :locals => {:l => lesson}
  end
  
  
  def card_display(card)
    if card.card_type
      render_to_string :partial => "lessons/display_note_card", :locals => {:c => card}
    end
  end
  
end
