class EditController < ApplicationController
  before_filter :find_user, :login => [:add_note]
  layout "ajax-edit", :only => [:lesson]

  # Ajax add actions
  def add_card
    if params[:id]
      @lesson_id = params[:id]
    end
    
    if params[:pos]
      @pos = params[:pos]
    end
    
    if @user && @user.role != "student"
      @card = Card.new(@user.login)
      @my_notes = []
      @my_embeds = []
      @my_images = []
      cards = Card.view(@user.login, "cards_by_author", {:author => @user.login})
      cards.each do |c|
        case c["card_type"]
          when "Note"
            @my_notes << c
          when "Embed"
            @my_embeds << c
          when "Image"
            @my_images << c
        end
      end
          
    else
      @card = nil
    end
    
    render :action => "add_#{params[:ctype]}"
  end
  
  def remove_card
    removed = false
    if params[:id] && params[:lesson_id]
      lesson = Lesson.find(@user.login, params[:lesson_id])
      if params[:pos]
        card = lesson.cards[params[:pos].to_i]
        if card && (card.split(":")[1] == params[:id])
          lesson.cards.delete_at(params[:pos].to_i)
          lesson = Lesson.save(@user.login, lesson.attributes)
          removed = true
        end
      else
        lesson.cards.each_with_index do |c, indx|
          if c == params[:id]
            lesson.cards.delete_at(indx)
            lesson = Lesson.save(@user.login, lesson.attributes)
            removed = true
            break
          end
        end  
      end
    end
    
    if removed
      #remove the card from the display
      render :update do |page|
        page.remove("card_#{params[:id]}")
      end
    else
      render :update do |page|
        page.insert_html :top, "card_#{params[:id]}", :text => "We couldn't remove that card at this time."
      end 
    end
    
  end

  # main show page
  def lesson
    # show a specific lesson
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
      #@identifiers.each_with_index do |idf, ndx|
      #    @lesson.post.gsub!(idf, "")
      #end
    end
    
  end
  
  # Ajax create actions
  def create_card
    if @user && @user.role != "student"
      pub = false
      if params[:card][:public] == "1"
        pub = true
      end
      cards = []
      
      card = Card.save(@user.login, params[:card], pub)
      if card && params[:lesson][:id]
        lesson = Lesson.find(@user.login, params[:lesson][:id])
        if lesson 
          if lesson.cards == nil
            lesson.cards = []
          end
          if params[:lesson][:position]
            #need to insert this note into the page data at the correct position.
            if card.commit
              lesson.cards.insert(params[:lesson][:position].to_i, "#{card.commit}:#{card._id}")
            else
              lesson.cards.insert(params[:lesson][:postion].to_i, "HEAD:#{card._id}")
            end
          else
            #put the card at the bottom
            if card.commit
              lesson.cards << "#{card.commit}:#{card._id}"
            else
              lesson.cards << "HEAD:#{card._id}"
            end
          end
         
          
          lesson = Lesson.save(@user.login, lesson.attributes)
          lesson = Lesson.find(@user.login, lesson._id)
          cards = lesson.cards.map do |card_id| 
            #determine if there are any versions stored with these card_ids
            version = "HEAD"
            res = card_id.split(":")
            if res[1] 
              version = res[0]
              card_id = res[1]
            end
            
            #if lesson.public
            #  Card.find(@user.login, card_id, "HEAD", true) #was version not HEAD
            #else
              Card.find(@user.login, card_id)
            #end

          end
        end
      end
    end
   
    #update the page with the newly created note
    render :update do |page|
      page.replace_html("lesson_display_area", :partial => "edit/lesson_refresh", :locals => {:lesson => lesson, :cards => cards})
      #page.visual_effect(:highlight, "card_#{card._id}", :duration => 3.0)
    end
   
  end
  
  def create_image_card
    if @user && @user.role != "student"
      pub = false
      if params[:card][:public] == "1"
        pub = true
      end
      cards = []
      #if there is a picture save it and get the filename
      if params[:picture] && params[:picture][:uploaded_data] != ""
        #create picture and attach it to the listing
        @picture = Image.new(params[:picture])
        if @picture.save
          params[:card][:post] = @picture.public_filename(:small)
        else
          params[:card][:post] = "No Picture Saved"
          flash[:notice] = "There was a problem saving your picture. Try a shrinking it to a smaller size before upload."
        end
      end

      card = Card.save(@user.login, params[:card], pub)
      if card && params[:lesson][:id]
        lesson = Lesson.find(@user.login, params[:lesson][:id])
        if lesson 
          if params[:lesson][:position]
            #need to insert this note into the page data at the correct position.
            if card.commit
              lesson.cards.insert(params[:lesson][:position].to_i, "#{card.commit}:#{card._id}")
            else
              lesson.cards.insert(params[:lesson][:postion].to_i, "HEAD:#{card._id}")
            end
          else
            #put the card at the bottom
            if card.commit
              lesson.cards << "#{card.commit}:#{card._id}"
            else
              lesson.cards << "HEAD:#{card._id}"
            end
          end


          lesson = Lesson.save(@user.login, lesson.attributes)
        end
      end
    end

    redirect_to :action => "lesson", :id => lesson._id 
  end
  
  def insert_card
    if params[:card_id] && params[:lesson_id]
      card = Card.find(@user.login, params[:card_id])
      lesson = Lesson.find(@user.login, params[:lesson_id])
      if card && lesson
       if params[:position]
          #need to insert this note into the page data at the correct position.
          if card.commit
            lesson.cards.insert(params[:position].to_i, "#{card.commit}:#{card._id}")
          else
            lesson.cards.insert(params[:position].to_i, "HEAD:#{card._id}")
          end
       else
        #put the card at the bottom
        if card.commit
          lesson.cards << "#{card.commit}:#{card._id}"
        else
          lesson.cards << "HEAD:#{card._id}"
        end
       end
       
        
        lesson = Lesson.save(@user.login, lesson.attributes)
        lesson = Lesson.find(@user.login, lesson._id)
        cards = lesson.cards.map do |card_id| 
          #determine if there are any versions stored with these card_ids
          version = "HEAD"
          res = card_id.split(":")
          if res[1] 
            version = res[0]
            card_id = res[1]
          end
          Card.find(@user.login, card_id)
        end
      end
    end
    
    #update the page with the newly created note
    render :update do |page|
      page.replace_html("lesson_display_area", :partial => "edit/lesson_refresh", :locals => {:lesson => lesson, :cards => cards})
      #page.visual_effect(:highlight, "card_#{card._id}", :duration => 3.0)
    end
    
  end
  
end
