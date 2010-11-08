#!/usr/bin/env ruby
require 'rubygems'
require 'set'
require 'digest/md5'
require 'monitor'

module Poodle
    class WorkQueue

        def initialize(initial = nil)
            @done = false
            @items = []
            @crawled = Set.new
            @items << initial if initial
            @items.extend(MonitorMixin)
        end

        def add(item) #as_unique and use names not "item"?
            @items.synchronize do
                id = unique_id(item[0])
                unless @crawled.include?(id)
                    @items << item
                    @crawled.add(id)
                end
            end
        end

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
        
        def unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end
    end
end
