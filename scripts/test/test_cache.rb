#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'sqlite3'
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
        referer = URI.parse("http://www.somewhere.com/")
        chk = "hello world"
    
        assert_equal false, cache.has?(uri)
        assert_equal nil, cache.get(URI.parse("http://www.ear.com/b.html"))
        cache.add(uri, nil, title, chk)
        assert_equal true, cache.has?(uri)
        assert_equal [1, uri, URI.parse(""), title, chk], cache.get(uri)
        cache.delete(uri)
        assert_equal false, cache.has?(uri)
        cache.add(uri, referer, title, chk)
        assert_equal [2, uri, referer, title, chk], cache.get(uri)
    end
    
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
        
        # Why is this failing?
        #cache = Cache.new(site1, at1, db)
        #assert_equal "", cache.last_crawled_site_at
    end
    
    def test_next_on_empty
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        iterator = cache.new_iterator

        iterator.next {|item| raise "should not be called" }
    end
    
    def test_next_one
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        iterator = cache.new_iterator
        uri = URI.parse("http://www.rat.com/halibut.html")
        cache.add(uri, URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        iterator.next {|item| assert_equal [1, uri, URI.parse("http://www.rat.com/wig.html"), "foo", "1234"], item }
        iterator.next {|item| raise "should not be called" }
    end
    
    def test_next_many
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        iterator = cache.new_iterator
        base_uri = "http://www.rat.com/halibut"
        expected = []
        0.upto(10) do |i|
            expectation = [i + 1, URI.parse(base_uri + i.to_s + ".html"), URI.parse("http://www.rat.com/wig.html"), "bar", i.to_s]
            expected << expectation
            cache.add(expectation[1], expectation[2], expectation[3], expectation[4])
        end
        0.upto(10) { |i| iterator.next {|item| assert_equal expected[i], item }}
        iterator.next {|item| raise "should not be called" }
        iterator.next {|item| raise "should not be called" }
    end
    
    def test_done
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        iterator = cache.new_iterator

        assert_equal true, iterator.done?
        cache.add(URI.parse("http://www.rat.com/halibut.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        assert_equal false, iterator.done?
        iterator.next {|item| assert_equal [1, URI.parse("http://www.rat.com/halibut.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234"], item }
        assert_equal true, iterator.done?
        cache.add(URI.parse("http://www.rat.com/halibut.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        assert_equal true, iterator.done?
        cache.add(URI.parse("http://www.rat.com/herring.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        assert_equal false, iterator.done?
        iterator.kill
        iterator.next {|item| raise "should not be called" }
        assert_equal true, iterator.done?
    end
    
    def test_threaded_simple
        db = SQLite3::Database.new(":memory:")
        cache = Cache.new(URI.parse("http://www.rat.com"), Time.parse('2010-02-01'), db)
        iterator = cache.new_iterator

        cache.add(URI.parse("http://www.rat.com/halibut.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234")
        a = Thread.new do
            assert_equal false, iterator.done?
            iterator.next {|item| assert_equal [1, URI.parse("http://www.rat.com/halibut.html"), URI.parse("http://www.rat.com/wig.html"), "foo", "1234"], item }
            iterator.next {|item| raise "should not be called" }
        end
        a.join
        b = Thread.new do
            assert_equal true, iterator.done?
            iterator.next {|item| raise "should not be called" }
        end
        assert_equal true, iterator.done?
        b.join
    end

    def test_from_path
        uri = URI.parse("http://www.rat.com/foo.html?a=b#1")
        at = Time.parse("2001-01-01")
        path = "~/home/foo/"
        
        SQLite3::Database.expects(:new).with(File.join(path, 'www_rat_com')).returns("not a real db")
        Cache.expects(:new).with(uri, at, "not a real db").returns(nil)
        Cache.from_path(uri, at, path)
        
        path = "~/home/bar"
        SQLite3::Database.expects(:new).with(File.join(path, 'www_rat_com')).returns("not a real db")
        Cache.expects(:new).with(uri, at, "not a real db").returns(nil)
        Cache.from_path(uri, at, path)
    end

  end
end
