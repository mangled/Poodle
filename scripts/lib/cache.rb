#!/usr/bin/env ruby
require 'sqlite3'
require 'thread'

module Poodle

    class Cache
        
        attr_accessor :last_crawled_site_at

        def initialize(site_uri, at, db = SQLite3::Database.new(":memory:"))
            @db = db

            create_tables()

            cached_site = @db.get_first_row("select * from sites where url = :url", :url => site_uri.to_s)
            if cached_site
                @last_crawled_site_at = Time.parse(cached_site[2])
                @db.execute("update sites set at = :at where id = :id", :at => at.to_s, :id => cached_site[0])
            else
                @db.execute("insert into sites values(?, ?, ?)", nil, site_uri.to_s, at.to_s)
            end

            @semaphore = Mutex.new
        end
        
        def Cache.from_path(site_uri, at, path)
            filename = File.join(path, site_uri.host.gsub(/\./, '_'))
            db = SQLite3::Database.new(filename)
            Cache.new(site_uri, at, db)
        end
        
        def new_iterator
            CacheIterator.new(@db)
        end

        def has?(uri)
            @semaphore.synchronize do
                !@db.get_first_row("select * from urls where url = :url", :url => uri.to_s).nil?
            end
        end
        
        def add(uri, referer, title, checksum)
            @semaphore.synchronize do
                cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
                unless cached_url
                    @db.execute("insert into urls values(?, ?, ?, ?, ?)", nil, uri.to_s, referer.to_s, title, checksum)
                    cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
                end
                cached_url
            end
        end

        def get(uri)
            @semaphore.synchronize { find(uri) }
        end

        def delete(uri)
            @semaphore.synchronize do
                cached_url = find(uri)
                @db.execute("delete from urls where id = :id", :id => cached_url[0]) if cached_url
            end
        end

    private

        def find(uri)
            cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
            if cached_url # Fixme: DRY - This is the same as the cache get()
                # .to_s required as windows seems to convert to int if it can! Look into this.
                referer = cached_url[2].empty? ? nil : URI.parse(cached_url[2])
                title = cached_url[3].to_s.empty? ? nil : cached_url[3].to_s
                chk = cached_url[4].to_s.empty? ? nil : cached_url[4].to_s
                [cached_url[0].to_i, URI.parse(cached_url[1]), referer, title, chk]
            end
        end

        def create_tables()
            @db.execute("create table if not exists sites(id integer primary key autoincrement, url string, at string)")
            @db.execute("create table if not exists urls(id integer primary key autoincrement, url string, referer string, title string, checksum string)")
        end
    end
    
    class CacheIterator

        def initialize(db)
            @db = db
            @done = false
            @semaphore = Mutex.new
        end

        def next
            unless @done
                yielded = false
                item = nil
                @semaphore.synchronize do
                    item = next_item
                    @current_id = item[0] if item
                    if next_empty?(@current_id)
                        yield item if (block_given? and item)
                        yielded = true
                    end
                end
                yield item if (block_given? and not yielded)
            end
        end
        
        def done?
            @semaphore.synchronize { next_item().nil? or @done }
        end

        def kill(with_message = false)
            puts "Shutting down work queue(s)..." if with_message
            @done = true
        end

    private

        def next_item
            cached_url = unless @current_id
                @db.get_first_row("select * from urls order by id")
            else
                @db.get_first_row("select * from urls where id > :id order by id", :id => @current_id)
            end
            if cached_url
                # .to_s required as windows seems to convert to int if it can! Look into this.
                referer = cached_url[2].empty? ? nil : URI.parse(cached_url[2])
                title = cached_url[3].to_s.empty? ? nil : cached_url[3].to_s
                chk = cached_url[4].to_s.empty? ? nil : cached_url[4].to_s
                [cached_url[0].to_i, URI.parse(cached_url[1]), referer, title, chk]
            end
        end

        def next_empty?(last_id)
            @db.get_first_row("select * from urls where id > :id order by id", :id => last_id).nil?
        end
    end
end
