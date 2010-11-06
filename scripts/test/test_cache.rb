#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'
require 'time'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'cache'

module Poodle

  class TestCache < Test::Unit::TestCase
    
    def test_urls
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.ear.com"), Time.parse('2010-01-01'), db)

        uri = URI.parse("http://www.ear.com/a.html")
        title = "Eating Space Suits"
        referer = nil
        chk = "hello world"

        assert_equal false, cache.has?(uri)
        assert_equal nil, cache.get(URI.parse("http://www.ear.com/b.html"))
        cache.add(uri, referer, title, chk)
        assert_equal true, cache.has?(uri)
        assert_equal [1, uri, URI.parse(""), title, chk], cache.get(uri)
        cache.delete(uri)
        assert_equal false, cache.has?(uri)
    end
    
    def test_last_crawled
        db = SQLite3::Database.new(":memory:")

        site1 = URI.parse("http://www.ear.com")
        at = Time.parse('2010-01-01')

        cache = Cache.new(site1, at, db)
        assert_equal nil, cache.last_crawled_site_at
        
        cache = Cache.new(site1, at, db)
        assert_equal at, cache.last_crawled_site_at
    end
    
    def test_delete_site_specific
        db = SQLite3::Database.new(":memory:")

        site1 = URI.parse("http://www.ear.com")
        at = Time.parse('2010-01-01')
        
        cache = Cache.new(site1, at, db)
        
        uri = URI.parse("http://www.ear.com/a.html")
        chk = "hello thing"
        assert_equal false, cache.has?(uri)
        cache.add(uri, URI.parse("http://www.rat.com/wig.html"), "cheese", chk)

        site2 = URI.parse("http://www.elbow.com")
        cache = Cache.new(site2, at, db)
        
        assert_equal true, cache.has?(uri)
        cache.add(uri, URI.parse("http://www.rat.com/wam.html"), "shoe", chk)
        cache.delete(uri)
        assert_equal true, cache.has?(uri)
    end

    def test_remove_on_empty
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        cache.remove {|item| raise "should not be called" }
    end
    
    def test_remove_one
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        uri = URI.parse("http://www.rat.com/halibut.html")
        cache.add(uri, URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        cache.remove {|item| assert_equal [1, uri, URI.parse("http://www.rat.com/wig.html"), "foo", "1234"], item }
        cache.remove {|item| raise "should not be called" }
    end

    def test_remove_many
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        base_uri = "http://www.rat.com/halibut"
        expected = []
        0.upto(10) do |i|
            expected << [i + 1, URI.parse(base_uri + i.to_s + ".html"), URI.parse("http://www.rat.com/wig.html"), "bar", "1234"]
            cache.add(expected[-1][1], expected[-1][2], expected[-1][3], expected[-1][4])
        end
        0.upto(10) { |i| cache.remove {|item| assert_equal expected[i], item }}
        cache.remove {|item| raise "should not be called" }
        cache.remove {|item| raise "should not be called" }
    end

  end
end
