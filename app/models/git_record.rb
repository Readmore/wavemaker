# A minimal class to help use Git as a backend datastore
class GitRecord

  attr_accessor :attributes
  
  def initialize
    @attributes = default_attributes
  end
  
  def self.update_branch(branch_name)
    # merge the master repo into this repo
    begin  
      repo = self.repo(self.repo_name)
      repo.branch(branch_name).checkout
      repo.merge("master")
      repo.commit("updated #{branch_name} branch with master")
      true
    rescue
      false
    end
  end
  
  def self.repo(r_name)
    puts "Getting #{r_name}"
    full_path_to_repo = "#{RAILS_ROOT}/#{r_name}"
    
    #Look for .git directory to see if this repo needs to be created
    #for now we assume it doesn't 
    repo = Git.open(full_path_to_repo)
    
  end
  
  ## default_attributes are determined by sub_classes
  def default_attributes
    {}
  end 
  
  def self.find(username, id, pub=false, version="HEAD")
    # id is a combination of obj_type, username, and filename. 
    # e.g. card/3423427122.mov or lesson/CS1043_iPhone_Development.html
    #given a username and file_id grab the specified hash from the file.
      #use the username to determine the correct directory to pull from
      #then just read hash on the directory + id
    
    # TODO 
    # if version is not HEAD then we need to find the specified version 
    # this can be accomplished on the command line with 
    # git cat-file blob HEAD^^^:public/users/brandon/Lessons/9ad1af20-cd8c-012b-735d-002332ced2f8
    # or git cat-file SHA-OF-COMMIT:path to file
    
      repo = self.repo(self.repo_name)
      if pub
        #checkout master branch
        repo.branches[:master].checkout
      else
        #checkout username branch
        repo.branches[username.to_sym].checkout
      end
      #Find this id on this branch
      res = repo.grep("_id => #{id}")
      obj = {}
      if res && res.first
         path = res.first[0].split(":")
         if path[1]
         #Do actual File system manipulation
          #file_path = "#{@base_dir}/#{@repo_name}/public/users/#{username}/#{obj_type}s/#{file_name}"
          file_path = "#{self.path_to_repo}/#{path[1]}"
          obj = self.read_hash(file_path)
         end
      end
     obj
  end
  
  def self.delete(username, id)
    # given a specified file delete it from the repo.
    # for now we do not allow deletion of public records
    repo = self.repo(repo_name)
    res = false
    repo.branch(username).checkout
    #obj = GitRecord.find(username, id)
    #Find this id on this branch
    obj = repo.grep("_id => #{id}")
    if obj && obj.first
      path = obj.first[0].split(":")
      if path[1]
        #Do actual File system manipulation
          full_path = "#{path_to_repo}/#{path[1]}"
          repo.remove(full_path)
          repo.commit("removed #{id} from #{username} branch")
          res = true
      end
    end
    res
  end
  
  def self.view(username, view_name, options={})
    #pull a specified query from the Git Repo
    #e.g. username: test, view_name: by_author, :options = hash of additional values to overwrite defaults
    repo = self.repo(self.repo_name)
    results = []
    view_res = {}
    
      repo.branch(username).checkout
        #if that didn't fail
        #view_res = eval("#{view_name}(#{repo}, #{options})")
        view_res = eval("self.#{view_name}(repo, options)")
    # convert results hash to array of obj attributes
    view_res.each_key do |key|
      file_path = key.split(":")
      if file_path[1]
        results << self.read_hash("#{self.path_to_repo}/#{file_path[1]}")
      end
    end
    results
    
  end 
  
  def self.save(username, attributes, pub)
    #take this attribute hash and save it to disk
    #return the object
    #get repo
    #update rev section so every update will create a commit, even if there is no change.
    if attributes[:_rev]
      attributes[:_rev] = (attributes[:_rev].to_i + 1).to_s
    else
      attributes[:_rev] = "0"
    end
    
    repo = self.repo(self.repo_name) #@repo_name)
    
    branches = []
    if pub
      branches << 'master'
    end
    
    branches << username
  
    branches.each do |branch|
      #checkout branch
      repo.branch(branch).checkout
      if attributes && attributes["type"] && attributes["_id"]
        #Do actual File system manipulation
        #Write Dirs and Files
        FileUtils.mkdir_p "#{self.path_to_repo}/#{username}/#{attributes["type"]}s"
        FileUtils.cd("#{self.path_to_repo}/#{username}/#{attributes["type"]}s") {
            puts "Wrote #{attributes['types']} #{attributes['_id']} with public val of #{attributes['public']}"
            self.write_hash(attributes, attributes["_id"])
        }
         #Check-in files to branch
          repo.add("#{self.path_to_repo}/#{username}/#{attributes["type"]}s/#{attributes["_id"]}")
          repo.commit("added #{attributes['_id']} version #{attributes['_rev']} to #{branch} branch")
      else
        #we didn't have a full object hash, no file was saved
        return false
      end
    end    
    
    true
  end
  
  def method_missing(method_symbol, *arguments)
      method_name = method_symbol.to_s
      
      case method_name[-1..-1]
      when "="
        @attributes[method_name[0..-2]] = arguments.first
      when "?"
        @attributes[method_name[0..-2]] == true
      else
        # Returns nil on failure so forms will work
        @attributes.has_key?(method_name) ? @attributes[method_name] : nil
      end
  end
  
  private
  
  def self.repo_name
    return "db/data"
  end
  
  def self.path_to_repo
    return "#{RAILS_ROOT}/#{repo_name}"
  end
  
  def self.write_hash(hash, file_name)
    #take the hash and write it to a file
    File.open(file_name, "w") { |f|
      hash.each_pair do |key, val| 
        if val.is_a?(String) 
          val = val.gsub("\n", "[ln]")
        end
        f.puts("#{key} => #{val}")
      end
    }

  end

  def self.read_hash(file_name)
    #get a hash from the file
    h1 = {}
    File.open(file_name, "r") { |f|
      f.each do |line|
        arr = line.split("=>")
        h1[arr[0].strip] = arr[1].strip.gsub("[ln]", "\n")
      end
    }
    h1
  end
  
  def id
    _id rescue nil
  end


  ##### Git View Section ####
  # Each View will be it's own function that wraps git grep and returns an array of values
  def self.cards_by_author(repo, params)
    #expect params["author"]
    res = repo.grep("author => #{params['author']}")
    out = {}
    res.each_key do |key, val|
      if key.include?("Cards")
        out[key] = val
      end
    end
    out
  end
  
  def self.by_type(repo, params)
    #expect params["type"]
    repo.grep("type => #{params['type']}")
  end
  
  def self.cards_by_public(repo, params)
    #pull all public cards
    res = repo.grep("public => 1")
    out = {}
    res.each_pair do |key, val|
      if key.include?("Cards")
        out[key] = val
      end
    end
    out
  end
  
  ### Lesson Views #############################
  def self.lessons_by_public(repo, params)
    #pull all public lessons
    res = repo.grep("public => 1")
    out = {}
    res.each_pair do |key, val|
      if key.include?("Lessons")
        out[key] = val
      end
    end
    out
  end
  
  def self.lessons_by_author(repo, params)
    #pull all courses by this author in repo
    res = repo.grep("author => #{params['author']}")
    out = {}
    res.each_pair do |key, val|
      if key.include?("Lessons")
        out[key] = val
      end
    end
    out
  end

  ### Course Views ############################
  def self.courses_by_public(repo, params)
    #pull all public courses
    res = repo.grep("public => 1")
    out = {}
    res.each_pair do |key, val|
      if key.include?("Courses")
        out[key] = val
      end
    end
    out
  end
  
  def self.courses_by_author(repo, params)
    #pull all courses by this author in repo
    res = repo.grep("author => #{params['author']}")
    out = {}
    res.each_pair do |key, val|
      if key.include?("Courses")
        out[key] = val
      end
    end
    out
  end

end