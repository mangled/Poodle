#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'sqlite3'
require 'uri'
require 'mocha'
require 'time'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'cache'
require 'synchronization'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'helpers'

module Poodle

  class TestCache < Test::Unit::TestCase

    def test_last_crawled
        db = SQLite3::Database.new(":memory:")
    
        site1 = URI.parse("http://www.ear.com")
        at1 = Time.parse('2010-01-01')
        at2 = Time.parse('2010-01-02')
    
        cache = Cache.new(site1, at1, db)
        assert_equal nil, cache.last_crawled_site_at
        
        cache = Cache.new(site1, at2, db)
        assert_equal at1, cache.last_crawled_site_at
        
        cache = Cache.new(site1, nil, db)
        assert_equal at2, cache.last_crawled_site_at

        cache = Cache.new(site1, at1, db)
        assert_equal nil, cache.last_crawled_site_at
    end
    
    def test_from_path
        uri = URI.parse("http://www.rat.com/foo.html?a=b#1")
        at = Time.parse("2001-01-01")
        path = "~/home/foo/"
        
        SQLite3::Database.expects(:new).with(File.join(path, 'www_rat_com__foo_html')).returns("not a real db")
        Cache.expects(:new).with(uri, at, "not a real db").returns(nil)
        Cache.from_path(uri, at, path)
        
        path = "~/home/bar"
        SQLite3::Database.expects(:new).with(File.join(path, 'www_rat_com__foo_html')).returns("not a real db")
        Cache.expects(:new).with(uri, at, "not a real db").returns(nil)
        Cache.from_path(uri, at, path)
    end
    
    def test_populate
        db = SQLite3::Database.new(":memory:")

        cache = Cache.new(URI.parse("http://www.ear.com"), Time.parse('2010-01-01'), db)
        expected = random_expectations
        cache.add(expected)

        queue = WorkQueue.new
        assert_equal 0, queue.processed.length
        assert_equal nil, queue.last_crawled_site_at
        cache.populate(queue)
        assert_equal nil, queue.last_crawled_site_at
        assert_equal 11, queue.remaining

        0.upto(10) {|i| queue.remove {|item| assert_equal expected[i], item } }
        assert_equal 0, queue.remaining
        
        cache = Cache.new(URI.parse("http://www.ear.com"), Time.parse('2010-01-01'), db)
        expected = random_expectations
        cache.add(expected)
        cache.populate(queue)
        assert_equal Time.parse('2010-01-01'), queue.last_crawled_site_at
        assert_equal 11, queue.remaining
    end
    
    def test_delete
      cache = Cache.new(URI.parse("http://www.ear.com"), Time.parse('2010-01-01'))
      cache.add(random_expectations)
      cache.delete
      queue = WorkQueue.new
      cache.populate(queue)
      assert_equal 0, queue.remaining
    end
    
    def random_expectations
      expected = []
      0.upto(10) do |i|
        expected << [UrlUtilities::random_url(), UrlUtilities::random_url(), i.to_s]
      end
      expected
    end
  end
end
