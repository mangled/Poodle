#!/usr/bin/env ruby
#
# Some **simple** purge tests - Not **exhaustive** but just enough to give some confidence!
# They are a bit messy and need some cleaning - Sorry...

require 'rubygems'
require 'test/unit'
require 'net/http'
require 'uri'
require 'mocha'
require 'fakeweb'
require 'set'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'purge'

class TestPurge < Test::Unit::TestCase

  def setup
      @log = mock()
      # Don't care about logging content tests (for now)
      @log.stubs(:info)
      @log.stubs(:warn)
      FakeWeb.allow_net_connect = false
  end

  def test_options_removes_slash
    options = PurgeOptions.get_options(['-s', 'http://foo/solr'])
    assert_equal "http://foo/solr", options[:solr_uri].to_s
    
    options = PurgeOptions.get_options(['-s', 'http://foo/solr/'])
    assert_equal "http://foo/solr", options[:solr_uri].to_s
    
    options = PurgeOptions.get_options(['-s', 'http://foo/'])
    assert_equal "http://foo", options[:solr_uri].to_s
    
    options = PurgeOptions.get_options(['-s', 'http://foo'])
    assert_equal "http://foo", options[:solr_uri].to_s
  end

  def test_no_urls
    mock_solr = mock()
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_response)
    SolrPurge.purge({ :solr => mock_solr, :log => @log })
  end
  
  def test_valid_urls
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/")
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :log => @log })
    assert_equal("me", FakeWeb.last_request["User-Agent"])
    assert_equal("foo", FakeWeb.last_request["From"])
  end
  
  # Need more exhaustive tests than this - i.e. think about which errors require a url to be deleted
  def test_skip_delete_with_401_unauthorized
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/", ["401", "Unauthorized"])
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :delete => true, :log => @log })
  end
  
  def test_invalid_url_with_redirection
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    mock_solr.expects(:delete_by_id).once.with('2').returns(nil)
    mock_solr.expects(:commit).once.with().returns(nil)
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/", ["301", "Moved Permanently"])
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :delete => true, :log => @log })
  end

  def test_invalid_url_with_delete
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    mock_solr.expects(:delete_by_id).once.with('2').returns(nil)
    mock_solr.expects(:commit).once.with().returns(nil)
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/", ["404", "Not Found"])
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :delete => true, :log => @log })
  end
  
  def test_invalid_url_no_delete # Common with the above, just a command line switch!
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/", ["404", "Not Found"])
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :log => @log })
  end

  def test_handles_net_fatal
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://foo.com/"}, { "id" => "2", "url" => "http://bar.com/"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    mock_solr.expects(:delete_by_id).once.with('2').returns(nil)
    mock_solr.expects(:commit).once.with().returns(nil)
    add_expect_uri("http://foo.com/")
    add_expect_uri("http://bar.com/", ["500", "Internal Server Error"])
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :delete => true, :log => @log })
  end

  def test_indexing_valid_urls
    mock_solr = mock()
    queries = sequence('queries')
    items1 = [ { "id" => "1", "url" => "http://foo.com/1"}, { "id" => "2", "url" => "http://foo.com/2"} ]
    items2 = [ { "id" => "3", "url" => "http://foo.com/3"}, { "id" => "4", "url" => "http://foo.com/4"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items1, 0, 4))
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 2, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items2, 4, 4))
  
    add_expect_uri("http://foo.com/1")
    add_expect_uri("http://foo.com/2")
    add_expect_uri("http://foo.com/3")
    add_expect_uri("http://foo.com/4")
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :log => @log })
  end

  def test_indexing_some_invalid_urls
    mock_solr = mock()
    queries = sequence('queries')
    items1 = [ { "id" => "1", "url" => "http://foo.com/1"}, { "id" => "2", "url" => "http://foo.com/2"} ]
    items2 = [ { "id" => "3", "url" => "http://foo.com/3"}, { "id" => "4", "url" => "http://foo.com/4"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items1, 0, 4))
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 2, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items2, 4, 4))
    mock_solr.expects(:delete_by_id).once.with('1').returns(nil)
    mock_solr.expects(:delete_by_id).once.with('3').returns(nil)
    mock_solr.expects(:commit).once.with().returns(nil)

    add_expect_uri("http://foo.com/1", ["404", "Not Found"])
    add_expect_uri("http://foo.com/2")
    add_expect_uri("http://foo.com/3", ["404", "Not Found"])
    add_expect_uri("http://foo.com/4")
    SolrPurge.purge({ :solr => mock_solr, :wait => 0, :user_agent => "me", :from => "foo", :log => @log, :delete => true })
  end

  def test_remove_matching_urls
    mock_solr = mock()
    items = [ { "id" => "1", "url" => "http://bart.com/"}, { "id" => "2", "url" => "http://bar.com/"}, { "id" => "3", "url" => "http://bar.com/a.html"} ]
    mock_solr.expects(:select).once.with({:q => 'id:*', :start=> 0, :rows=>10, :wt => :ruby, :fl =>'id,url'}).returns(make_item_response(items))
    add_expect_uri("http://bart.com/")
    SolrPurge.purge({ :solr => mock_solr, :remove => "http://bar.com/", :wait => 0, :user_agent => "me", :from => "foo", :log => @log })
    assert_equal("me", FakeWeb.last_request["User-Agent"])
    assert_equal("foo", FakeWeb.last_request["From"])
  end

  # Helpers
  
  def add_expect_uri(url, status = ["200", "OK"], body = '', content_type = '')
    FakeWeb.register_uri(:head, url, :body => body, :content_type => content_type, :status => status)
  end
  
  def make_item_response(items, start = 0, found = nil)
    make_response(start, found||items.length, items.length, items)
  end

  def make_response(start = 0, found = 0, rows = 0, items = [])
        response = {
          "responseHeader" => { "params" => { "rows" => rows.to_s } },
          "response" => { "start" => start.to_s, "numFound" => found.to_s, "docs" => items }
      }
  end

end
