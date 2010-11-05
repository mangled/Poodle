#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'cache'

module Poodle
  # THIS IS WIP !!
  class TestCache < Test::Unit::TestCase
    
    def test_urls
      cache = Cache.new
      uri = URI.parse("http://www.ear.com/a.html")
      assert_equal false, cache.has?(uri)
      cache.add(uri)
      assert_equal true, cache.has?(uri)
      cache.delete(uri)
      assert_equal false, cache.has?(uri)
    end
    
  end  
end