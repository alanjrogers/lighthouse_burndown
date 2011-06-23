module Burndown
  class Milestone
    include DataMapper::Resource

    property :id,                   Serial
    property :remote_id,            Integer,  :required => true
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
      due = due_on || Time.now
      closed = closed_at || Time.now
      Date.parse([due, closed].max.to_s)
    end

    def past_due?
      due_on && due_on < Time.now
    end

    def active?
      return true if open_tickets_count > 0
      return true if due_on && !past_due?
      return false
    end

    def percent_complete
      return "N/A" if tickets_count <= 0;
      ((tickets_count - open_tickets_count).to_f/tickets_count.to_f*100).to_i
    end
    
    def percent_time_complete
      return 0 if tickets_count <= 0;
      first_event = self.milestone_events.first(:order => [:created_on.asc])
      last_event = self.milestone_events.first(:order => [:created_on.desc])
      
      if last_event == first_event
        return 0
      end
      
      if first_event.hours_left.to_f == 0.0
        return 0
      end
      
      percentage = ((first_event.hours_left.to_f - last_event.hours_left.to_f)/(first_event.hours_left.to_f)*100).to_i
      
      if percentage > 100
        percentage = 100
      end
      
      if percentage < 0
        percentage = 0
      end
      
      (last_event.nil? or first_event.nil?) ? "N/A" : percentage
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

      results = Lighthouse.get_milestone_tickets(self.name, self.project.remote_id, self.project.token.account, self.project.token.token, self.tickets_count)
      ticket_ids = results["tickets"] ? results["tickets"].collect{ |t| t["number"] }.join(",") : ""
      total = 0.0
      
      if results["tickets"]
        results["tickets"].each { |t|
            if t['state'] == 'resolved' or t['state'] == 'invalid' then
              next
            end
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
                total += splitsville[1].to_f
              end
            end
          }
      end
      
      existing_event = self.milestone_events.first(:created_on.gte => Date.today, :milestone_id => self.id)
      if (existing_event)
        existing_event.update(:open_tickets => ticket_ids, :hours_left => total)
      else
        self.milestone_events.create(:open_tickets => ticket_ids, :hours_left => total)
      end
      
      first_milestone = self.milestone_events.first(:order => [:created_on.desc])
      
      if first_milestone.created_on < self.activated_at
        self.activated_at = first_milestone.created_on
      end
    end

  end
end