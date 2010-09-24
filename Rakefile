require 'rake'
require File.dirname(__FILE__) + "/lib/relevant/hudson.rb"

require 'rspec/core/rake_task'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gemspec|
    gemspec.version = Relevant::Hudson::Version
    gemspec.name = "relevant-hudson"
    gemspec.summary = "Hudson widget for Relevant"
    gemspec.description = "Check the time"
    gemspec.email = "opensource@thinkrelevance.com"
    gemspec.homepage = "http://github.com/relevance/relevant-hudson"
    gemspec.authors = ["Jared Pace", "Rob Sanheim"]
    gemspec.add_dependency "relevant-widget", "~> 0.0.6"
    gemspec.add_dependency "feedzirra"
    gemspec.add_development_dependency "rspec", "~> 2.0.0.beta.22"
  end
  Jeweler::GemcutterTasks.new
  
rescue LoadError
  puts "Jeweler not available. Install it with: gem install jeweler"
end

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec)
task :default => :spec

task :full_release => [:check_dependencies, :spec, :release]