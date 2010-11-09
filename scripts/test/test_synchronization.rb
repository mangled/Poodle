#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'mocha'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'synchronization'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'helpers'

module Poodle
  class TestQueue < Test::Unit::TestCase
  
    def test_queue
      queue = WorkQueue.new
  
      assert_equal nil, queue.last_crawled_site_at
      assert_equal 0, queue.processed.length
  
      assert_equal true, queue.done?
      queue.remove {|item| assert_equal nil, item }
      assert_equal true, queue.done?

      expected = populate(queue)
      0.upto(10) {|i| queue.remove {|item| assert_equal expected[i], item } }
      assert_equal true, queue.done?
      assert_equal 11, queue.processed.length
      0.upto(10) {|i| assert_equal expected[i], queue.processed[i] }

      populate(queue)
      assert_equal false, queue.done?
      queue.kill
      assert_equal true, queue.done?
      
      expected = UrlUtilities::random_url()
      queue = WorkQueue.new([expected, expected, "xyz"])
      queue.remove {|item| assert_equal [expected, expected, "xyz"], item }
      queue.remove {|item| raise "should not be called" }
      assert_equal true, queue.done?
      
      queue = WorkQueue.new()
      expected = [UrlUtilities::random_url(), UrlUtilities::random_url(), "tyeuie"]
      queue.add(expected[0], expected[1], expected[2])
      queue.add(expected[0], expected[1], expected[2])
      queue.remove {|item| assert_equal expected, item }
      queue.remove {|item| raise "should not be called" }
      assert_equal 1, queue.processed.length
    end
  
    def populate(queue)
      expected = []
      0.upto(10) do |i|
        value = [UrlUtilities::random_url(), UrlUtilities::random_url(), i.to_s]
        queue.add(value[0], value[1], value[2])
        expected << value
        assert_equal false, queue.done?
      end
      expected
    end
    
  end
end