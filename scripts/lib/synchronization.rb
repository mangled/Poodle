#!/usr/bin/env ruby
require 'rubygems'
require 'set'
require 'digest/md5'
require 'monitor'

module Poodle
    class WorkQueue

        attr_accessor :last_crawled_site_at

        def initialize(initial = nil)
            @done = false
            @items = []
            @processed = []
            @crawled = Set.new
            @items.extend(MonitorMixin)
            add(initial[0], initial[1]) if initial
        end

        # Bad name - It only adds new/unseen
        def add(uri, referer)
            @items.synchronize do
                id = unique_id(uri)
                unless @crawled.include?(id)
                    @items << [uri, referer]
                    @crawled.add(id)
                end
            end
        end

        def remove()
            yielded = false
            item = nil
            @items.synchronize do
                item = @items.shift
                @processed << item if item
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
        
        def processed
            @processed
        end

        def unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end
    end
end
