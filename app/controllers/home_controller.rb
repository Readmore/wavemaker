class HomeController < ApplicationController
  before_filter :find_user, :login => [:dashboard]
  layout "ajax-edit"

  def index
    
  end
  
  def dashboard
    # Get my latest private data
    if @user
      @my_courses = Course.view(@user.login, "courses_by_author", {:author => @user.login})
      @my_lessons = Lesson.view(@user.login, "lessons_by_author", {:author => @user.login})
      @my_cards = Card.view(@user.login, "cards_by_author", {:author => @user.login})
    end
    
      # Get latest public data
      @public_cards = Card.view("master", "cards_by_public")
      @public_lessons = Lesson.view("master", "lessons_by_public")
      @public_courses = Course.view("master", "courses_by_public")  
  end

  def card
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
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @card }
    end
  end

  def lesson
     # show a specific lesson; without editing ability
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
      @cards = []

      if !@lesson.attributes.empty? && @lesson.cards
        #num = @lesson.cards.length
        #parse lesson.post and find and card identifiers [fc:x] where x is the array index
        #@identifiers = num.times.map {|x| "[fc:#{x}]"}
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
      end
  end

  def course
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

      respond_to do |format|
        format.html # show.html.erb
        format.xml  { render :xml => @course }
      end
  end
  
  private
  
  def find_user
    @user = User.find_by_id(session[:user_id])
  end
  
  def lesson_display(lesson)
    render_to_string :partial => "courses/display_lesson_card", :locals => {:l => lesson}
  end

end
