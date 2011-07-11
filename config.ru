#!/usr/bin/env ruby
require "rubygems"
require "bundler/setup"
require "./lib/burndown"

# Load configuration and initialize Burndown
Burndown.new(File.dirname(__FILE__) + "/config/config.yml")

# You probably don't want to edit anything below
Burndown::App.set :environment, ENV["RACK_ENV"] || :production
Burndown::App.set :port,        8910
Burndown::App.set :bd_username, ENV["BD_USERNAME"] || "admin"
Burndown::App.set :bd_password, ENV["BD_PASSWORD"] || "password"

run Burndown::App
