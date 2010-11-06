#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'
require 'time'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'cache'

module Poodle
  # THIS IS WIP !!
  class TestCache < Test::Unit::TestCase
    
    def test_urls
        db = SQLite3::Database.new(":memory:")

        site1 = URI.parse("http://www.ear.com")
        at = Time.parse('2010-01-01')
        cache = Cache.new(site1, at, db)
        assert_equal nil, cache.last_crawled_site_at

        uri = URI.parse("http://www.ear.com/a.html")
        chk = "hello world"

        assert_equal false, cache.has?(uri)
        assert_equal nil, cache.get(URI.parse("http://www.ear.com/b.html"))
        cache.add(uri, chk)
        assert_equal true, cache.has?(uri)
        assert_equal [1, uri, chk], cache.get(uri)
        cache.delete(uri)
        assert_equal false, cache.has?(uri)
        
        # Two sites share a url, check delete doesn't kill it
        cache = Cache.new(site1, at, db)
        assert_equal at, cache.last_crawled_site_at
        
        assert_equal false, cache.has?(uri)
        cache.add(uri, chk)

        site2 = URI.parse("http://www.elbow.com")
        cache = Cache.new(site2, at, db)
        
        assert_equal true, cache.has?(uri)
        cache.add(uri, chk)
        cache.delete(uri)
        assert_equal true, cache.has?(uri)
    end

  end  
end
