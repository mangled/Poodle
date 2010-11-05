#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'mocha'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'synchronization'

module Poodle
  class TestQueue < Test::Unit::TestCase
  
    def test_queue
      queue = WorkQueue.new
  
      assert_equal true, queue.done?
      queue.remove {|item| assert_equal nil, item }

      expected = populate(queue)
      0.upto(10) {|i| queue.remove {|item| assert_equal expected[i], item } }
      assert_equal true, queue.done?

      populate(queue)
      assert_equal false, queue.done?
      queue.kill
      assert_equal true, queue.done?
      
      queue = WorkQueue.new(1)
      queue.remove {|item| assert_equal 1, item }

      queue = WorkQueue.new([1, 2])
      queue.remove {|item| assert_equal [1, 2], item }
    end
  
    def populate(queue)
      expected = []
      0.upto(10) do |i|
        value = rand(100)
        queue.add(value)
        expected << value
        assert_equal false, queue.done?
      end
      expected
    end
    
    def test_crawled_set
      set = CrawledSet.new
      assert_equal 0, set.length
      assert_equal false, set.seen?(1)
      set.add(1)
      assert_equal 1, set.length
      assert_equal true, set.seen?(1)
      set.add(1)
      assert_equal 1, set.length
    end
    
  end
end