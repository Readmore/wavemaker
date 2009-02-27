class HomeController < ApplicationController
  before_filter :find_user, :login => [:dashboard]
  layout "default"

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

  
  private
  
  def find_user
    @user = User.find_by_id(session[:user_id])
  end

end
