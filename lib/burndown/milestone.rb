module Burndown
  class Milestone
    include DataMapper::Resource

    property :id,                   Serial
    property :remote_id,            Integer,  :required => true, :index => :unique
    property :name,                 String
    property :activated_at,         DateTime
    property :closed_at,            DateTime
    property :due_on,               DateTime
    property :tickets_count,        Integer, :default => 0
    property :open_tickets_count,   Integer, :default => 0

    belongs_to :project
    has n, :milestone_events

    def start_date
      @@start_date ||= Date.parse(activated_at.to_s)
    end

    def end_date
      due = due_on || Time.now.to_datetime
      closed = closed_at || Time.now.to_datetime
      Date.parse([due, closed].max.to_s)
    end

    def past_due?
      due_on && due_on < Time.now.to_datetime
    end

    def active?
      return false if self.activated_at.nil?
      return true if open_tickets_count > 0
      return true if due_on && !past_due?
      return false
    end

    def activate
        self.activated_at = Time.now()
        self.save
        self.sync_with_lighthouse
    end

    def percent_complete
      return "N/A" if tickets_count <= 0;
      ((tickets_count - open_tickets_count).to_f/tickets_count.to_f*100).to_i
    end
    
    def percent_time_complete
      return 0 if tickets_count <= 0;
      last_event = self.milestone_events.first(:order => [:created_on.desc])
      
      percentage = (last_event.hours_elapsed.to_f/(last_event.hours_left.to_f + last_event.hours_elapsed.to_f)*100).round
      
      if percentage > 100
        percentage = 100
      end
      
      if percentage < 0
        percentage = 0
      end
      last_event.nil? ? "N/A" : percentage
    end
    
    def time_left
      last_event = self.milestone_events.first(:order => [:created_on.desc])
      last_event.nil? ? "N/A" : last_event.hours_left
    end

    def external_url
      "http://#{self.project.token.account}.#{Burndown.config[:lighthouse_host]}/projects/#{self.project.remote_id}/milestones/#{self.remote_id}"
    end

     # Queries the API for each milestone (yikes!). Hope you don't have too many.
    def self.sync_with_lighthouse
      Milestone.all.each do |milestone|
        if milestone.project.active?
          milestone.sync_with_lighthouse
        end
      end
    end

    # Syncs up the milestone with lighthouse updates
    def sync_with_lighthouse
      results = Lighthouse.get_milestone(self.remote_id, self.project.remote_id, self.project.token.account, self.project.token.token)
      return false unless milestone = results["milestone"]
      self.update(:name => milestone["title"], :due_on => milestone["due_on"], :tickets_count => milestone["tickets_count"], :open_tickets_count => milestone["open_tickets_count"])
      if !self.active?
        self.update(:closed_at => Time.now)
      else
        self.update(:closed_at => nil) if !self.closed_at.nil?
      end

      tickets = Lighthouse.get_milestone_tickets(self.name, self.project.remote_id, self.project.token.account, self.project.token.token)
      ticket_ids = tickets ? tickets.collect{ |t| t["number"] }.join(",") : ""
      total_left = 0.0
      total_elapsed = 0.0
      
      if tickets
        tickets.each { |t|
           tags = t['tag']
            if tags.nil?
              next
            end
            all_tags = tags.split(" ")
            if all_tags.nil?
              next
            end
            all_tags.each do |tag|
              splitsville = tag.split(":")
            
              if splitsville.size == 2 and splitsville[0] == "hours"
                if t['state'] == "open" or t['state'] == "new" then
                  total_left += splitsville[1].to_f
                end
              end
              if splitsville.size == 2 and splitsville[0] == "elapsed" then
                total_elapsed += splitsville[1].to_f
              end
            end
          }
      end
      
      existing_event = self.milestone_events.first(:created_on.gte => Date.today, :milestone_id => self.id)
      if (existing_event)
        existing_event.update(:open_tickets => ticket_ids, :hours_left => total_left, :hours_elapsed => total_elapsed)
      else
        self.milestone_events.create(:open_tickets => ticket_ids, :hours_left => total_left, :hours_elapsed => total_elapsed)
      end
    end

  end
end
