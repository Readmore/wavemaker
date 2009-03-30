class Indexer
  
  def add(attrs, branches, username)
    
    branches.each do |branch|
      repo = GitRecord.repo(branch)
    
      path = "#{repo.dir.to_s}/#{attrs["type"]}s/#{attrs["_id"]}"
      #Check for this file
      f = Filelist.find(:first, :conditions => ["path = ? AND current = ?", path, true])
      if f 
        #Entry already exists
        f.current = false
        f.save
      end
      
      #Create file entry for searching
      f = Filelist.new
      f.path = path
      f.version = attrs["version"]
      f.title = attrs["title"]
      f.repo = branch 
      f.record_type = attrs["type"]
      f.author = username
      f.current = true
      f.save
      
       # Get words
        post_data = attrs["title"] + " " + attrs["post"]
        words = post_data.split(" ")
        in_tag = false;
        # Link each word to this file;
    		words.each_with_index do |w, i|
    		  if in_tag
    		    if w.rindex(">")
    		      in_tag = false
    		      next
    		    end
  		    else 
    		    #remove words within html tags
      		  if w[0..0] == "<"
      		    in_tag = true
      		    next
    		    end
    		    
    		    #Stem the word - must also stem words at query time
    		    w = stem_word(w)
    		    thisword = Word.find(:first, :conditions => ["word = ?", w])
    		    if thisword == nil
             # new word
             thisword = Word.create(:word => w)
    		    end
    		    #set word location
            wl = Wordloc.create(:file_id => f.id, :word_id => thisword.id, :location => i)     
          end
        end
    end
   
  end
  
  def stem_word(word)
    #remove any suffixs from this word
    # crude removal of ly, ing, s, and es
    len = word.length
    word.gsub!("'", "")
    word.gsub!('"', "")
    word.gsub!(".", "")
    #remove any trailing html
    x = word.rindex("<") 
    if x
      word = word[0..x-1]
    end
    
    if word[len-2..len] == "ly"
      #found ly
      #check for ingly
      if word[len-5..len] == "ingly"
        word = word[0..len-6]
      else
        word = word[0..len-3]
      end
      return word
    end
    
    if word[len-3..len] == "ing"
      return word[0..len-4]
    end
    
    if word.rindex("es")
      return word[0..len-3]
    end
    
    if word.rindex("s")
      return word[0..len-2]
    end
    word.downcase
  end
  
end