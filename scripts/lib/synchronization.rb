#!/usr/bin/env ruby
require 'rubygems'
require 'set'
require 'digest/md5'
require 'thread'

module Poodle
    class WorkQueue

        attr_accessor :last_crawled_site_at

        def initialize(initial = nil)
            @user_cancelled = false
            @items = []
            @processed = []
            @crawled = Set.new
            @removing_mutex = Mutex.new
            @check_removing = ConditionVariable.new
            @items_mutex = Mutex.new
            @removing = 0
            add(initial[0], initial[1], initial[2]) if initial
        end

        # Bad name - It only adds new/unseen
        # Should take in a hash or array
        def add(uri, referer, checksum)
            @items_mutex.synchronize do
                id = unique_id(uri)
                unless @crawled.include?(id)
                    @items << [uri, referer, checksum]
                    @crawled.add(id)
                end
            end
        end

        def remove()
            @removing_mutex.lock
            item = @items.shift
            while (@removing > 0) and item.nil?
                @check_removing.wait(@removing_mutex)
                item = @items.shift
            end
            if item.nil?
                @check_removing.signal
                @removing_mutex.unlock
            else
                @removing += 1
                @removing_mutex.unlock
                begin
                    @processed << (yield item)
                ensure
                    @removing_mutex.lock
                    @removing -= 1
                    @check_removing.signal
                    @removing_mutex.unlock
                end
            end
            return !(@user_cancelled or item.nil?)
        end

        def kill(with_message = false)
            puts "Shutting down work queue(s)..." if with_message
            @user_cancelled = true
        end
        
        def processed
            @items_mutex.synchronize { @processed }
        end

        def remaining
            @items_mutex.synchronize { @items.length }
        end

        def unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end
    end
end
