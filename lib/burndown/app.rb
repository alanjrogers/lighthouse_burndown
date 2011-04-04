require 'authorization'

module Burndown
  class App < Sinatra::Base
    set :root,     File.dirname(__FILE__) + "/../.."
    set :app_file, __FILE__
    enable :sessions

    include Burndown
    include Burndown::Helpers
    
    include Sinatra::Authorization
    
    before do 
      require_authentication
    end
    
    get "/" do
      @projects = Project.all
      show :index
    end

    get "/project/:id" do
      @project = Project.get(params[:id])
      @milestones = @project.milestones.all(:order => [:due_on.asc]).sort { |x, y|
        pos = nil
        pos = -1 if y.due_on.nil?
        pos = 1 if x.due_on.nil?
        pos =  0 if x.due_on.nil? && y.due_on.nil?
        pos = x.due_on <=> y.due_on if pos.nil?
        pos
      }
      show :project
    end

    get "/timeline/:id" do
      @milestone = Milestone.get(params[:id])
      @timeline_events = @milestone.milestone_events(:order => [:created_on.desc])
      show :timeline
    end

    get "/setup" do
      @tokens = Token.all
      show :setup
    end

    # Validates a token (AJAX method)
    post "/token_validity" do
      @token = Token.new(params[:token])
      status (@token.valid_lighthouse_token? ? 200 : 500)
    end

    # Creates a new token (AJAX method)
    post "/tokens" do
      return if Burndown.config[:demo_mode]

      @token = Token.new(params[:token])
      @token.set_data
      if @token.save
        status 200
      else
        status 500
      end
    end

    post "/projects" do
      return if Burndown.config[:demo_mode]

      token = Token.get(params[:token_id])
      Project.activate_remote(params[:project_remote_id], token, request.host)
      redirect "/setup"
    end

  end
end