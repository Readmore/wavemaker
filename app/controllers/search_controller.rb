class SearchController < ApplicationController
  before_filter :find_user 
  layout "default"
  
  def index
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
  
end

private

def find_user
  @user = User.find_by_id(session[:user_id])
end