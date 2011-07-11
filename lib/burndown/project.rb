module Burndown
  class Project
    include DataMapper::Resource

    property :id,             Serial
    property :remote_id,      Integer,  :required => true
    property :name,           String,   :required => true
    property :active_since,   DateTime
    property :secret_hash,    String
    property :hours_per_day,  Float

    belongs_to :token
    has n, :milestones

    # Calls the api to get projects for the token
    def self.for_token(token)
      result = Lighthouse.get_projects(token.account, token.token)
      arr = []
      (result["projects"] || []).each do |project|
        p = Project.first(:remote_id => project["id"].to_i, :token => token) || Project.new(:name => project["name"], :remote_id => project["id"], :token => token)
        arr.push(p)
      end
      arr
    end

    # Activates (starts tracking) a remote project
    def self.activate_remote(remote_id, token, host="example.com")
      result = Lighthouse.get_project(remote_id, token.account, token.token)
      result = result["project"]
      p = Project.new(:name => result["name"], :remote_id => result["id"], :active_since => Time.now)
      p.token = token
      p.save
      p.create_starting_milestones!
      p.save
      p
    end
    
    # De-activates (stops tracking) a remote project
    def self.deactivate_remote(project_id)
      p = Project.get(project_id)
      p.destroy
    end

    # Asks the API for existing milestones and saves them for later use
    def create_starting_milestones!
      result = Lighthouse.get_milestones(self.remote_id, self.token.account, self.token.token)
      (result["milestones"] || []).each do |milestone|
        m = self.milestones.create(:name => milestone["title"], :remote_id => milestone["id"], :due_on => milestone["due_on"])
      end
    end

    def update_milestones!
        result = Lighthouse.get_milestones(self.remote_id, self.token.account, self.token.token)
        (result["milestones"] || []).each do |milestone|
            existing = Milestone.all(:remote_id => milestone["id"])
            if existing.count > 0
                existing[0].sync_with_lighthouse
            else
                m = self.milestones.create(:name => milestone["title"], :remote_id => milestone["id"], :due_on => milestone["due_on"])
            end
        end
    end

   # Queries the API for each milestone (yikes!). Hope you don't have too many.
    def self.sync_with_lighthouse
      Project.all.each do |project|
        if project.active?
            project.update_milestones!
        end
      end
    end
    # Creates a lighthouse callback
    def create_callback!(host)
      self.secret_hash = Digest::SHA1.hexdigest("lighthouse#{self.id}#{rand(10000)}callback")
      Lighthouse.create_callback(self.id, "http://" + host + "/lighthouse_callbacks/#{self.id}/#{secret_hash}", self.token.account, self.token.token)
    end

    def active?
      active_since && active_since <= Time.now.to_datetime
    end
  end
end