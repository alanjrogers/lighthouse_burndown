module Burndown
  class MilestoneEvent
    include DataMapper::Resource
    
    property :id,               Serial
    property :open_tickets,     Text,   :default => "" # comma-separated ids: 1,2,3
    property :hours_left,       Float, :default => 0.0
    property :hours_elapsed,    Float, :default => 0.0
    property :created_on,       Date
    
    belongs_to :milestone
    
    def prev_record
      @prev_record ||= (self.class.first(:created_on.lt => self.created_on, :milestone_id => self.milestone_id, :order => [:created_on.desc]) || MilestoneEvent.new)
    end
    
    def num_tickets_open
      @num_tickets_open ||= self.open_tickets.split(',').size
    end
    
    def tickets_opened
      @tickets_opened ||= (self.open_tickets.split(',') - prev_record.open_tickets.split(',')).size
    end
    
    def tickets_closed
      @tickets_closed ||= (prev_record.open_tickets.split(',') - self.open_tickets.split(',')).size
    end
    
    def ticket_change
      tickets_opened - tickets_closed
    end
    
    def hours_change
      self.hours_left - prev_record.hours_left
    end
    
  end
end
