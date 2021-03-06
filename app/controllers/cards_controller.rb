class CardsController < ApplicationController
  before_filter :find_user, :login => [:new, :edit, :create, :update, :destroy]
  layout "default", :except => [:new_ui, :edit_ui]
  
  # GET /cards
  # GET /cards.xml
  def index
    #@posts = post.find(database_name, )
    if @user
      @cards = Card.view(@user.login, "cards_by_author", {:author => "@user.login"})
    else
      @cards = []
    end
    
    @public_cards = Card.view("master", "cards_by_public")
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cards}
    end
  end

  # GET /cards/1
  # GET /cards/1.xml
  def show
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
  
  def ajax_show
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
    
    render :layout => false
  end

  # GET /cards/new
  # GET /cards/new.xml
  def new
    if @user && @user.role != "student"
      @card = Card.new(@user.login)
    else
      @card = nil
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @card }
    end
  end
  
  def new_ui  
   if @user && @user.role != "student"
      @card = Card.new(@user.login)
    else
      @card = nil
    end
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @card }
    end
  end
  
  def edit_ui
    if @user && @user.role != "student"
      @card = Card.find(@user.login, params[:id])
    else
      @card = nil
    end
  end

  # GET /cards/1/edit
  def edit
    if @user && @user.role != "student"
      @card = Card.find(@user.login, params[:id])
    else
      @card = nil
    end

  end

  # POST /cards
  # POST /card.xml
  def create
    if @user && @user.role != "student"
      pub = false
      if params[:card][:public] == "1"
        pub = true
      end
      card = Card.save(@user.login, params[:card], pub)
      
    end
    if params[:form_type]
      redirect_to :controller => "ui", :action => :card_view, :id => card.attributes["_id"]
    else
      respond_to do |format|
          flash[:notice] = 'card was successfully created.'
          format.html { redirect_to card_url(card.attributes["_id"]) }
          format.xml  { render :xml => card, :status => :created, :location => card }
      end
    end
  end

  def clone
    # take the card with this id from master and save it to the user's repo
    if params[:id] && params[:version]
      if @user.role == "admin" || @user.role == "faculty"
        if Card.clone(@user.login, params[:id], params[:version])
          flash[:notice] = "Card Cloned to Your Data!"
        end
      end
    end 
    # redirect to Dashboard
    redirect_to :controller => :home, :action => "dashboard"  
    
  end

  # PUT /cards/1
  # PUT /cards/1.xml
  def update_ui
    if @user && @user.role != "student"
      @card = Card.find(@user.login, params[:card]["_id"])
      pub = false
      if params[:card][:public] == "1"
        pub = true
      end

      @card = Card.save(@user.login, params[:card], pub)
    else
      @card = nil
    end
    
    #if params["form_type"]
      redirect_to :controller => "ui", :action => :card_view, :id => @card.attributes["_id"]
    #else
    #  respond_to do |format|
    #      flash[:notice] = 'card was successfully updated.'
    #      format.html { redirect_to card_url(@card.attributes["_id"]) }
    #      format.xml  { head :ok }
    #  end
    #end
  end

  # DELETE /cards/1
  # DELETE /cards/1.xml
  def destroy
    if @user
      @card = Card.delete(@user.login, params[:id])
    else
      @card = nil
    end
    respond_to do |format|
      format.html { redirect_to(:controller => "ui", :action => "home") }
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

#  <% c.attributes.each_pair do |key, val| %>
#  	<span><i><%=key %></i> => <%= val %><br/></span>
#  <% end %>

end
