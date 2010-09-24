require "relevant/widget"
require "feedzirra"

module Relevant
  class Hudson
    Version = "0.0.1"
    include Relevant::Widget

    available_options :title => :string, 
                      :rss_feed => :string, 
                      :ignore_projects => :string, 
                      :http_auth_username => :string, 
                      :http_auth_password => :password
                      
    refresh_every 1.minute
    
    template_format :haml
    template %q[
%h2 Hudson - #{@options[:title]}
%ul.hudson-builds
  - builds.each do |build|
    %li.build{:class => build.label}
      %span.indicator
      %h3= build.project.titleize
      %em Build ##{build.number} - #{build.status}
:css
  ul.hudson-builds li.failing { padding-left: 37%; height: 3em; margin-bottom: 0.5em; }
  ul.hudson-builds li.failing .indicator {
    display: block;
    width: 50%;
    height: 3em;
    float: left;
    margin-left: -58%;
    background-color: #fc2015;
    border-radius: 5px;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
  }
  ul.hudson-builds li.failing h3 { margin-bottom: 0}
  ul.hudson-builds li.failing em { color: #BBB; font-size: 0.8em; }
  
  ul.hudson-builds li.building { padding-left: 37%; height: 1.5em; margin-bottom: 0.5em; }
  ul.hudson-builds li.building .indicator {
    display: block;
    width: 50%;
    height: 1.5em;
    float: left;
    margin-left: -58%;
    background-color: #fcce15;
    border-radius: 5px;
    -moz-border-radius: 5px;
    -webkit-border-radius: 5px;
  }
  ul.hudson-builds li.building h3 { margin-bottom: 0}
  ul.hudson-builds li.building em { display:none; }
  
  ul.hudson-builds li.passing {
    float: left;
    margin-right: 1.5em;
    padding: 5px 0 5px 18px;
  }
  ul.hudson-builds li.passing .indicator {
    display: block;
    width: 14px;
    height: 14px;
    float: left;
    margin-left: -18px;
    background-color: #4ad026;
    border-radius: 7px;
    -moz-border-radius: 7px;
    -webkit-border-radius: 7px;
  }
  ul.hudson-builds li.passing h3 { font-size: 1.1em; margin: 0;}
  ul.hudson-builds li.passing em { display: none }
  ul.hudson-builds li .indicator {
    box-shadow: 1px 1px 3px #222;
    -moz-box-shadow: 1px 1px 3px #222;
    -webkit-box-shadow: 1px 1px 3px #222;
  }
:javascript
  function animateHudsonBuilds() {
    $('ul.hudson-builds li.building .indicator').animate({opacity:0.05},2000,function(){
      $('ul.hudson-builds li.building .indicator').animate({opacity:1},2000,animateHudsonBuilds);
    });
  }
  animateHudsonBuilds();
]
    
    def builds
      return [] unless feed.respond_to?(:entries) # Error fetching feed
      
      builds = feed.entries.map{|rss_entry| Build.new(rss_entry)}
      builds.reject! {|build| build.project.match Regexp.new(@options[:ignore_projects], true)} if @options[:ignore_projects].present?
      builds.sort
    end
      
    def feed
      return unless @options[:rss_feed].present?
      
      feed_options = {:timeout => 10}
      feed_options[:http_authentication] = [@options[:http_auth_username], @options[:http_auth_password]] if @options[:http_auth_username].present?
      
      @feed ||= Feedzirra::Feed.fetch_and_parse(@options[:rss_feed], feed_options)
    end
      
    class Build
      TitleRegexp = /^(.*) #(\d+) \((.*)\)$/
      
      attr_reader :rss_entry
      
      def initialize(rss_entry)
        @rss_entry = rss_entry
      end
      
      def passing?
        status.match(/(stable|back to normal)/i)
      end
      
      def failing?
        status.match(/broken/)
      end
      
      def building?
        status.match(/^\?$/)
      end
      
      def project
        rss_entry.title.match(TitleRegexp)[1]
      end
      
      def number
        rss_entry.title.match(TitleRegexp)[2]
      end
      
      def status
        rss_entry.title.match(TitleRegexp)[3]
      end
      
      def label
        if passing?
          'passing'
        elsif failing?
          'failing'
        elsif building?
          'building'
        end
      end
      
      def <=>(other_build)
        order  = ['failing','building','passing']
        result = order.index(self.label) <=> order.index(other_build.label)
        result = self.project <=> other_build.project if result.zero?
        result
      end
    end
  end
end

Relevant.register Relevant::Hudson