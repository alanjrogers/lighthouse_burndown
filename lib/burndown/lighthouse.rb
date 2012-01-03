module Burndown
  class Lighthouse
    include HTTParty
    format :xml
    
    def self.lighthouse_host
      Burndown.config[:lighthouse_host]
    end
    
    def self.default_headers(token)
      {'X-LighthouseToken' => token}
    end
    
    def self.get_token(account, token)
      get "http://#{account}.#{lighthouse_host}/tokens/#{token}.xml", :headers => default_headers(token)
    end
    
    def self.get_projects(account, token)
      get "http://#{account}.#{lighthouse_host}/projects.xml", :headers => default_headers(token)
    end
    
    def self.get_project(remote_id, account, token)
      get "http://#{account}.#{lighthouse_host}/projects/#{remote_id}.xml", :headers => default_headers(token)
    end
    
    def self.get_milestones(remote_project_id, account, token)
      get "http://#{account}.#{lighthouse_host}/projects/#{remote_project_id}/milestones.xml", :headers => default_headers(token)
    end
    
    def self.get_milestone(remote_milestone_id, remote_project_id, account, token)
      get "http://#{account}.#{lighthouse_host}/projects/#{remote_project_id}/milestones/#{remote_milestone_id}.xml", :headers => default_headers(token)
    end
    
    def self.get_milestone_tickets(milestone_name, remote_project_id, account, token)
      page = 1
      all_results = []
      total_pages = 1
      begin
        result_set = get("http://#{account}.#{lighthouse_host}/projects/#{remote_project_id}/tickets.xml", :query => {:q => "milestone:\"#{milestone_name}\" sort:number" , :limit => 100, :page => page}, :headers => default_headers(token))
        if result_set.nil? or result_set["tickets"].nil?
          break
        end
        total_pages = result_set["tickets"][0].to_i
        all_results << result_set["tickets"][2..-1]
        all_results.flatten!
        page = page + 1
      end while page <= total_pages
      all_results
    end
    
    def self.create_callback(project_id, url, account, token)
      post "http://#{account}.#{lighthouse_host}/callback_handlers.xml", :query => {:callback_handler =>{
        :project_id => project_id,
        :url => url
      }}, :headers => default_headers(token)
    end
  end
end