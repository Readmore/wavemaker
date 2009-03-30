class CoursesController < ApplicationController
    include CoursesHelper
    #layout "default"

    before_filter :find_user, :login => [:index, :new, :edit, :create, :update, :destroy]

    # GET /courses
    # GET /courses.xml
    def index
      
      if @user
        @courses = Course.view(@user.login, "courses_by_author", {:author => @user.login})
      else
        @courses = []
      end

      @public_courses = Course.view("master", "courses_by_public")

      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @courses}
      end
    end

    # GET /courses/1
    # GET /courses/1.xml
    def show
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

    # GET /courses/new
    # GET /courses/new.xml
    def new
      if @user
        @course = Course.new(@user.login)
      else
        @course = nil
      end
      respond_to do |format|
        format.html # new.html.erb
        format.xml  { render :xml => @course }
      end
    end

    # GET /courses/1/edit
    def edit
      if @user
        @course = Course.find(@user.login, params[:id])
        @course.lessons = @course.lessons.join(",")
      else
        @course = nil
      end

    end

    # POST /course
    # POST /course.xml
    def create
      if @user
        pub = false
        if params[:course][:public] == "1"
          pub = true
        end
        course = Course.save(@user.login, params[:course], pub)
      end

      respond_to do |format|
          flash[:notice] = 'lesson was successfully created.'
          format.html { redirect_to course_url(course.attributes["_id"]) }
          format.xml  { render :xml => course, :status => :created, :location => course }
      end
    end

    def clone
      # take the course with this id from master and save it to the user's repo
      if params[:id] && params[:version]
        if @user.role == "admin" || @user.role == "faculty"
          if Course.clone(@user.login, params[:id], params[:version])
            flash[:notice] = "Course, Lessons, and Cards Cloned to Your Data!"
          end
        end
      end 
      # redirect to Dashboard
      redirect_to :controller => :home, :action => "dashboard"  

    end

    # PUT /courses/1
    # PUT /courses/1.xml
    def update
      if @user
        @course = Course.find(@user.login, params[:id])
        pub = false
        if params[:public] == "1"
          pub = true
        end

        @course.save(@user.login, params[:course], pub)
      else
        @course = nil
      end

      respond_to do |format|
          flash[:notice] = 'lesson was successfully updated.'
          format.html { redirect_to course_url(@course.attributes["_id"]) }
          format.xml  { head :ok }
      end
    end

    # DELETE /courses/1
    # DELETE /courses/1.xml
    def destroy
      if @user
        @course = Course.delete(@user.login, params[:id])
      else
        @course = nil
      end
      respond_to do |format|
        format.html { redirect_to(course_url) }
        format.xml  { head :ok }
      end
    end

    def attachment
    #  @post = Post.find(database_name, params[:id])
    #    metadata = @post._attachments[params[:filename]]
    #    data = Post.db(database_name).fetch_attachment(@post.id,
    #      params[:filename])
    #    send_data(data, {
    #      :filename    => params[:filename],
    #      :type        => metadata['content_type'],
    #      :disposition => "inline",
    #    })

    end

    private

    def lesson_display(lesson)
        render_to_string :partial => "display_lesson_card", :locals => {:l => lesson}
    end


  #	<h3>Lesson Info</h3>
  #  	<% @lesson.attributes.each_pair do |key, val| %>
  #  		<span><i><%=key %></i> => <%= val %><br/></span>
  #  	<% end %>

  #  	<%= link_to "Back", :action => :index %> | 
  #  	<% if @user.login == @lesson.author %>
  #  		<%= link_to "Edit", :action => :edit, :id => @lesson._id %> |
  #  		<%= link_to "Destroy", card_path(@lesson._id), :method => :delete %>
  #  	<% end %
end
