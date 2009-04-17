class Searcher
  require 'sqlite3'
  
  def initialize(env="development")
    @db = SQLite3::Database.new("db/#{env}.sqlite3")
  end
  
  def get_scored_list(rows, wordids)
    
    totalscores = {}
    weights = [[1.2, frequency_score(rows)], [1.4, location_score(rows)], [1.5, distance_score(rows)]]
    
    weights.each do |weight, scores|
      rows.each do |row|
        if totalscores[row[1]]
          totalscores[row[1]] += weight * scores[row[1]]
        else
          totalscores[row[1]] = weight * scores[row[1]]
        end
      end
    end
    
    return totalscores
    
  end
  
  def frequency_score(rows)
    h = {}
    rows.each do |row|
      if h[row[1]]
         h[row[1]] = h[row[1]] + 1
      else
         h[row[1]] = 1
      end  
    end
    normalize_scores(h.to_a)
  end
  
  def location_score(rows)
    locations = {}
    rows.collect { |row| locations[row[1]] = 100000 }
    rows.each do |row|
      loc = 1
      row.each_with_index do |item, i|
        if i > 1
          loc = loc + item.to_i
        end
      end
      locations[row[1]] = loc < locations[row[1]] ? loc : locations[row[1]]
    end
    return normalize_scores(locations.to_a, true)
  end
  
  def distance_score(rows)
    if rows[0] && rows[0].length > 3
      #multi-word query
      min_dists = {}
      rows.collect {|row| min_dists[row[1]] = 100000}
      
      rows.each do |row|
        num = row.length - 3
        dist = 0
        num.times do |i|
          dist += (row[3+i].to_i - row[3+i-1].to_i).abs
        end
        min_dists[row[1]] = dist < min_dists[row[1]] ? dist : min_dists[row[1]]
      end
      return normalize_scores(min_dists.to_a, true)
    else
      scores = {}
      rows.collect { |row| scores[row[1]] = 1.0 }
      return scores
    end
  end
  
  def normalize_scores(scores, smallIsBetter=false)
    h = {}
    if scores.length > 0
      vsmall = 0.00001
      if smallIsBetter
        minscore = scores.sort {|a,b| a[1]<=>b[1] }[0][1]
        scores.collect! {|u,s| [u, (minscore.to_f / (vsmall > s.to_f ? vsmall : s.to_f))]}
      else
        maxscore = scores.sort { |a,b| b[1] <=> a[1] }[0][1]
        maxscore = maxscore == 0 ? vsmall : maxscore 
        scores.collect! {|u,s| [u, s.to_f / maxscore]}
      end
      scores.each do |ele|
        h[ele[0]] = ele[1]
      end  
    end
      h
  end
  
  def get_file_path(file_id)
    f = Filelist.find(file_id)
    f.path
  end
  
  def search(q, repos=["master"])
    results = []
    files = query(q)
    files.each do |file|
      hit = [Filelist.find(file[0]), file[1]]
      hit[0].id = hit[0].path.split("/").last
      if hit[0].current && repos.include?(hit[0].repo)
        results << hit
      end 
    end
    results.uniq
  end
  
  def query(q)
    rows,wordids = get_match_rows(q)
    scores = get_scored_list(rows,wordids)
    ranked_scores = scores.sort { |a,b| b[1]<=>a[1] }
  end  
  
  def get_match_rows(query)
    #split the query into words
    query_words = query.downcase.split(" ")
    
    #setup indexer for word stemming
    indx = Indexer.new
    fields = []
    tables = []
    conditions = []
    wordids = []
    
    query_words.each_with_index do |w, i|
      #for each word query words table for it
      #stem the words before querying db
      w = indx.stem_word(w)
      # if it is found add that word id to the query list for word locs
      word = Word.find_by_word(w)
      if word
        wordids << word.id
        #this word exists
         #query needs to be built to look like this for two words
          # select w0.file_id, w0.location, w1.location
          # from wordlocs wo, wordlocs w1
          # where w0.file_id = w1.file_id
          # and w0.word_id = id1
          # and w1.word_id = id2
        
        if fields.length == 0
          fields << "w#{i}.id"
          fields << "w#{i}.file_id"
        end
        fields << "w#{i}.location"
        tables << "wordlocs w#{i}"
        conditions << "w#{i}.word_id = #{word.id}"
      end
    end
     
    rows = []
    if tables.length > 0
      #assemble the query and get results
      fullquery = "select #{fields.join(', ')} from #{tables.join(', ')} where #{conditions.join(' and ')}" # group by w0.id"
      rows = @db.execute(fullquery)    
    end
    return rows, wordids
  end
  
end