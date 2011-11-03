#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'thwait'

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
      assert_equal 0, queue.remaining

      queue.remove {|item| assert_equal nil, item }
      assert_equal 0, queue.remaining

      expected = populate(queue)
      0.upto(10) do |i|
        queue.remove do |item|
          assert_equal expected[i], item
          item
        end
      end
      assert_equal 0, queue.remaining
      assert_equal 11, queue.processed.length
      0.upto(10) {|i| assert_equal expected[i], queue.processed[i] }

      queue = WorkQueue.new
      expected = populate(queue)
      0.upto(10) do |i|
        queue.remove do |uri, referer, checksum|
          assert_equal expected[i], [uri, referer, checksum]
          ["a", "b", "c"]
        end
      end
      assert_equal 0, queue.remaining
      assert_equal 11, queue.processed.length
      0.upto(10) {|i| assert_equal ["a", "b", "c"], queue.processed[i] }
      
      expected = UrlUtilities::random_url()
      queue = WorkQueue.new([expected, expected, "xyz"])
      queue.remove {|item| assert_equal [expected, expected, "xyz"], item }
      queue.remove {|item| raise "should not be called" }
      assert_equal 0, queue.remaining
      
      queue = WorkQueue.new()
      expected = [UrlUtilities::random_url(), UrlUtilities::random_url(), "tyeuie"]
      queue.add(expected[0], expected[1], expected[2])
      queue.add(expected[0], expected[1], expected[2])
      assert_equal 1, queue.remaining

      queue.remove {|item| assert_equal expected, item }
      queue.remove {|item| raise "should not be called" }
      assert_equal 1, queue.processed.length
    end
    
    # These tests cannot hope to catch all potential thread issues, but does check for
    # gross synchronization/dead-lock issues.
    ##################################################################################

    # Here we check that the first thread eats the "seed" and if it doesn't emit
    # data the second thread doesn't remove and process
    def test_threading_empty_queue
      # We will start with a queue with a single value
      queue = WorkQueue.new()
      initial_item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "checksum"]
      queue.add(initial_item[0], initial_item[1], initial_item[2])

      threads = []
      threads << Thread.new {
        ok = queue.remove do |item|
          assert_equal initial_item, item
          ["thread A has processed"]
        end
        assert_equal true, ok
        assert_equal false, queue.remove {|item| assert false}
      }
      threads[0].join # Wait for first to process
      threads << Thread.new {
        assert_equal false, queue.remove {|item| assert false}
      }

      threads.each {|t| t.join }
      threads.each {|t| assert_equal false, t.status, "terminated ok" }
      assert_equal 0, queue.remaining
      assert_equal 1, queue.processed.length
      assert_equal ["thread A has processed"], queue.processed[0]
    end

    # Check that no thread ends up waiting to exit, but all workers have
    # finished - Resulting in a deadlock on the join
    def test_no_deadlock_on_empty
      queue = WorkQueue.new()
      item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "checksum"]
      queue.add(item[0], item[1], item[2])

      # Arrange for two threads to be queued/waiting - On exit
      # all threads must finish or we could get a deadlock on the main
      # thread's join
      threads = []
      threads << Thread.new {
        ok = queue.remove do |item|
          sleep(0.5)
          ["thread A has processed"]
        end
        assert ok
      }

      # ensure a gets run first and the next two threads end up waiting
      sleep(0.25)

      threads << Thread.new {
        assert !queue.remove {|item| puts "B"; assert "false" }
      }
      threads << Thread.new {
        assert !queue.remove {|item| puts "C"; assert "false" }
      }

      threads[2].join # Wait for last - i.e. "C" must not still be wating else deadlock
      threads.each {|t| t.join } # Wait all
      threads.each {|t| assert_equal false, t.status, "terminated ok" }
      assert_equal 0, queue.remaining
      assert_equal 1, queue.processed.length
      assert_equal ["thread A has processed"], queue.processed[0]
    end

    # Check that the synchronization code handles exceptions being thrown
    # If it fails to, then deadlock could occur, e.g. threads waiting on
    # might be wait forever
    def test_no_deadlock_on_exception
      # We will start with a queue with a single value
      queue = WorkQueue.new()
      initial_item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "seed"]
      queue.add(initial_item[0], initial_item[1], initial_item[2])
      
      # The first thread will "eat" the seed, then we schedule two other threads
      # which will block as the queue is empty, we then throw an exception in
      # the first thread and join - The join will deadlock if the remaining threads
      # have not been signalled and run to completion
      
      # The crawler uses threadswait, this swallows exceptions (ruby 1.8.6 does,
      # not sure about other versions), if the code was changed to using a simple
      # join "on" each then exceptions would propagate and this test could be used
      # to simply assert exceptions propagate outwards
      # Regardless of threadswait implementation, this test has value.
      threads = ThreadsWait.new

      threads.join_nowait(Thread.new {
        queue.remove do |item|
          sleep(0.2)
          raise "Bang!"
          ["thread A has processed"]
        end
      })
      threads.join_nowait(Thread.new { queue.remove {|item| assert false } })
      threads.join_nowait(Thread.new { queue.remove {|item| assert false } })

      threads.all_waits

      assert_equal 0, queue.remaining
      assert_equal 0, queue.processed.length
    end

    # Check that if the thread returns data the second thread eats it
    def test_threading_queue_generate_an_item
      # We will start with a queue with a single value
      queue = WorkQueue.new()
      initial_item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "checksum"]
      queue.add(initial_item[0], initial_item[1], initial_item[2])

      threads = []
      threads << Thread.new {
        queue.remove do |item|
          assert_equal initial_item, item
          queue.add(UrlUtilities::random_url(), UrlUtilities::random_url(), "made by A")
          ["thread A has processed"]
        end
      }
      threads[0].join # Wait for first to process
      threads << Thread.new {
        queue.remove do |item|
          assert_equal "made by A", item[2]
          ["thread B has processed"]
        end
      }

      threads.each {|t| t.join }
      threads.each {|t| assert_equal false, t.status, "terminated ok" }
      assert_equal 0, queue.remaining
      assert_equal 2, queue.processed.length
      assert_equal ["thread A has processed"], queue.processed[0]
      assert_equal ["thread B has processed"], queue.processed[1]
    end

    # A more general test where "n" threads run for a while emitting results
    # This contains random numbers on purpose, to ensure that if threading errors
    # exist, it will increase the chance they turn up (at some point!)...
    def test_threading_in_general
      # We will start with a queue with a single value
      queue = WorkQueue.new()
      initial_item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "seed"]
      queue.add(initial_item[0], initial_item[1], initial_item[2])

      emit_count = []
      threads = []
      (rand(5) + 1).times do |i|
        threads << Thread.new {
          items_made = 0
          items_eaten = 0
          produce_items_n_times = rand(50) + 1
          ok = true
          while ok
            ok = queue.remove do |item|
              raise "item should not be nil" if item.nil? # Don't have random unit test assert counts
              sleep(0.01) # Represents doing something and matches current code (it sleeps)
              if produce_items_n_times > 0
                rand(10).times do |i|
                  queue.add(UrlUtilities::random_url(), UrlUtilities::random_url(), "#{Thread.current.object_id} #{items_eaten}-#{i}")
                  items_made += 1
                end
                produce_items_n_times -= 1
              end
              items_eaten += 1
              ["thread #{Thread.current.object_id} processed #{item[2]}"]
            end
          end
          [items_eaten, items_made]
        }
      end

      threads.each {|t| t.join }
      assert threads.all? {|t| t.status == false }
      assert_equal 0, queue.remaining

      items_eaten = threads.inject(0){|sum, n| sum + n.value[0] }
      items_made = threads.inject(1){|sum, n| sum + n.value[1] } # 1 because of the first seed
      assert_equal items_made, queue.processed.length
      assert_equal items_eaten, items_made
    end
    
    # Check that the kill request functions
    def test_kill
      # We will start with a queue with a single value
      queue = WorkQueue.new()
      initial_item = [UrlUtilities::random_url(), UrlUtilities::random_url(), "seed"]
      queue.add(initial_item[0], initial_item[1], initial_item[2])
      
      # Make some threads and run "forever" (unless kill called)
      threads = []
      (rand(5) + 1).times do |i|
        threads << Thread.new {
          ok = true
          while ok
            ok = queue.remove do |item|
              sleep(0.01) # Represents doing something and matches current code (it sleeps)
              queue.add(UrlUtilities::random_url(), UrlUtilities::random_url(), "#{Thread.current.object_id} #{i}")
              ["thread #{Thread.current.object_id} processed #{item[2]}"]
            end
          end
        }
      end

      queue.kill

      threads.each {|t| t.join }
      assert threads.all? {|t| t.status == false }
    end

    # Helper to populate a queue with some stuff
    def populate(queue)
      expected = []
      0.upto(10) do |i|
        value = [UrlUtilities::random_url(), UrlUtilities::random_url(), i.to_s]
        queue.add(value[0], value[1], value[2])
        expected << value
        assert_not_equal 0, queue.remaining
      end
      expected
    end
    
  end
end