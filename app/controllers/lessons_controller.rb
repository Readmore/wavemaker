class LessonsController < ApplicationController
  include LessonsHelper
  layout "default"
  
  before_filter :find_user, :login => [:index, :new, :edit, :create, :update, :destroy]
  
  # GET /lessons
  # GET /lessons.xml
  def index
    if @user
      @lessons = Lesson.view(@user.login, "lessons_by_author", {:author => @user.login})
    else
      @lessons = []
    end
    
    #This could be done within the users's branch....
    @public_lessons = Lesson.view("master", "lessons_by_public")
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @lessons}
    end
  end

  # GET /lessons/1
  # GET /lessons/1.xml
  def show 
    branch = "master"
    
    if @user && !params[:pub]
      branch = @user.login
    end
    
    if params[:version]
      @lesson = Lesson.find(branch, params[:id], params[:version])
    else
      @lesson = Lesson.find(branch, params[:id])
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
          Card.find(branch, card_id, version, true)
        else
          Card.find(branch, card_id)
        end
      end
    
      #each time an identifier is found pull that card object from the array and insert 
        # the correct html for the card....
      #save this page to lesson post and the cards will render inline with the lesson
      @identifiers.each_with_index do |idf, ndx|
          @lesson.post.gsub!(idf, card_display(@cards[ndx]))
      end 
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @lesson }
    end
  end

  # GET /lessons/new
  # GET /lessons/new.xml
  def new
    if @user
      @lesson = Lesson.new(@user.login)
    else
      @lesson = nil
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @lesson }
    end
  end

  # GET /lessons/1/edit
  def edit
    if @user
      @lesson = Lesson.find(@user.login, params[:id])
      @lesson.cards = @lesson.cards.join(",")
    else
      @lesson = nil
    end

  end

  # POST /lesson
  # POST /lesson.xml
  def create
    if @user
      pub = false
      if params[:lesson][:public] == "1"
        pub = true
      end
      lesson = Lesson.save(@user.login, params[:lesson], pub)
    end
    
    respond_to do |format|
        flash[:notice] = 'lesson was successfully created.'
        format.html { redirect_to lesson_url(lesson.attributes["_id"]) }
        format.xml  { render :xml => lesson, :status => :created, :location => lesson }
    end
  end

  # PUT /lessons/1
  # PUT /lessons/1.xml
  def update
    if @user
      @lesson = Lesson.find(@user.login, params[:id])
      pub = false
      if params[:public] == "1"
        pub = true
      end

      @lesson.save(@user.login, params[:lesson], pub)
    else
      @lesson = nil
    end
    
    respond_to do |format|
        flash[:notice] = 'lesson was successfully updated.'
        format.html { redirect_to lesson_url(@lesson.attributes["_id"]) }
        format.xml  { head :ok }
    end
  end

  # DELETE /lessons/1
  # DELETE /lessons/1.xml
  def destroy
    if @user
      @lesson = Lesson.delete(@user.login, params[:id])
    else
      @lesson = nil
    end
    respond_to do |format|
      format.html { redirect_to(lesson_url) }
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
  
  def find_user
    @user = User.find_by_id(session[:user_id])
  end
  
  def card_display(card)
    #case card.card_type
    #when "Video"
      if card.card_type
        render_to_string :partial => "display_note_card", :locals => {:c => card}
      end
    #else
    #  render_to_string :partial => "display_card", :locals => {:c => card}
    #end
  end

   	
#	<h3>Lesson Info</h3>
#  	<% @lesson.attributes.each_pair do |key, val| %>
#  		<span><i><%=key %></i> => <%= val %><br/></span>
#  	<% end %>

#  	<%= link_to "Back", :action => :index %> | 
#  	<% if @user.login == @lesson.author %>
#  		<%= link_to "Edit", :action => :edit, :id => @lesson._id %> |
#  		<%= link_to "Destroy", card_path(@lesson._id), :method => :delete %>
#  	<% end %>

end
