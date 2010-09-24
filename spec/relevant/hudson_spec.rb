require 'spec_helper'

describe Relevant::Hudson do
  
  describe "#feed" do
    it 'fetches and parses the RSS feed' do
      hudson = Relevant::Hudson.setup(:rss_feed => 'http://hudson.example.com/rssLatest')
      
      Feedzirra::Feed.expects(:fetch_and_parse).with('http://hudson.example.com/rssLatest', {:timeout => 10}).returns(:feed)
      hudson.feed.should == :feed
    end
    
    it 'will pass basic auth credentials if provided' do
      hudson = Relevant::Hudson.setup(
        :rss_feed => 'http://hudson.example.com/rssLatest',
        :http_auth_username => 'admin',
        :http_auth_password => 'letmein'
      )
      
      Feedzirra::Feed.expects(:fetch_and_parse).with(
        'http://hudson.example.com/rssLatest', {
          :timeout => 10,
          :http_authentication => ['admin','letmein']
        })
      hudson.feed
    end
  end
  
  describe '#builds' do
    before do
      @passing_entry = stub('entry', :title => 'Bar Project #15 (stable)')
      @failing_entry = stub('entry', :title => 'Foo Project #99 (broken since build #85)')
      @hudson = Relevant::Hudson.setup
      @hudson.stubs(:feed).returns(stub('feed', :title => 'RSS Feed', :entries => [@passing_entry, @failing_entry]))
    end
    
    it 'translates rss entries into builds' do
      @hudson.builds.all?{|build| build.is_a? Relevant::Hudson::Build}.should be_true
    end
    
    it 'sorts the builds to have failing ones first' do
      @hudson.builds.first.should be_failing
    end
    
    it 'ignores projects by matching against its name' do
      hudson = Relevant::Hudson.setup :ignore_projects => '^foo'
      hudson.stubs(:feed).returns(stub('feed', :title => 'RSS Feed', :entries => [@passing_entry, @failing_entry]))
      
      hudson.builds.map(&:project).should_not include('Foo Project')
    end
  end
  
  describe Relevant::Hudson::Build do
    it 'knows the project of the build' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (broken since build #85)')
      build.project.should == 'Foo Project'
    end
    
    it 'knows the number of the build' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (broken since build #85)')
      build.number.should == '99'
    end
    
    it 'knows the status of the build' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (broken since build #85)')
      build.status.should == 'broken since build #85'
    end
    
    it 'is passing if the build is stable' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (stable)')
      build.should be_passing
    end
    
    it 'is passing if the build is back to normal' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (back to normal)')
      build.should be_passing
    end
    
    it 'is failing if the build is broken' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (broken since build #85)')
      build.should_not be_passing
      build.should be_failing
    end
    
    it 'is building if the status is unknown' do
      build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (?)')
      build.should_not be_passing
      build.should_not be_failing
      build.should be_building
    end
    
    context 'label' do
      it "is 'passing' if the build is passing?" do
        build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (stable)')
        build.label.should == 'passing'
      end
      
      it "is 'building' if the build is building?" do
        build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (?)')
        build.label.should == 'building'
      end
      
      it "is 'failing' if the build is failing?" do
        build = Relevant::Hudson::Build.new stub('entry', :title => 'Foo Project #99 (broken)')
        build.label.should == 'failing'
      end
    end
  end
  
end