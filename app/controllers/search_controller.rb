class SearchController < ApplicationController
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
      files = @searcher.query(query)
      files.each do |file|
        hit = [Filelist.find(file[0]), file[1]]
        hit[0].id = hit[0].path.split("/").last
        @results << hit 
      end
    end
  end
  
end
