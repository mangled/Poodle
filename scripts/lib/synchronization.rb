#!/usr/bin/env ruby
require 'rubygems'
require 'set'
require 'monitor'

module Poodle
    class WorkQueue

        def initialize(initial = nil)
            @done = false
            @items = []
            @items << initial if initial
            @items.extend(MonitorMixin)
        end

        def add(item)
            @items.synchronize { @items << item }
        end

        # This needs explanation!
        # It's very subtle and is present to stop deadlock on the main thread, basically
        # I couldn't wait on an empty queue because it's possible all threads will block
        # and the main thread will hang. This is an atypical use of threads, they are
        # both producing and consuming content.
        #
        # When a thread removes an item, if the queue is empty it yields it within the
        # mutex. This ensures that any thread blocked on the mutex will wait - In the
        # hope that when the yield (and the mutex) returns there might be some more content.
        # If there isn't then nothing has been added and it doesn't yield, if there is the same
        # pattern continues. This stops deadlock in the main thread and is quite nice!
        def remove()
            yielded = false
            item = nil
            @items.synchronize do
                item = @items.shift
                if @items.empty?
                    yield item if (block_given? and item)
                    yielded = true
                end
            end
            yield item if (block_given? and not yielded)
        end

        def done?
            @items.synchronize { @items.empty? or @done }
        end

        def kill(with_message = false)
            puts "Shutting down work queue(s)..." if with_message
            @done = true
        end
    end

    class CrawledSet

        def initialize()
            @crawled = Set.new
            @crawled.extend(MonitorMixin)
        end
        
        def add(id)
            @crawled.synchronize do
                @crawled.add(id)
            end
        end

        def seen?(id)
            @crawled.synchronize do
                @crawled.include?(id)
            end
        end

        def length
            @crawled.synchronize do
                @crawled.length
            end
        end
    end
end
