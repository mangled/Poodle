#!/usr/bin/env ruby
require 'sqlite3'

module Poodle
    class Cache
        # Need to work out deletion of items (use seen list?) and how to iterate from the work-queue
        # Iterate from cache instead of work-queue (need adapter): Use next_id, ">" and first_row? for remove
        # If a new url appears add to cache. At the end I need to iterate "seen" and delete any url's "not" seen
        # this seems costly, but it has to be done at the end unless I record url -> links.
        
        attr_accessor :last_crawled_site_at
    
        def initialize(site_uri, at, db)
            @db = db
            create_tables

            cached_site = @db.get_first_row("select * from sites where url = :url", :url => site_uri.to_s)
            if cached_site
                @last_crawled_site_at = Time.parse(cached_site[2])
                @db.execute("update sites set at = :at where id = :id", :at => at.to_s, :id => cached_site[0])
            else
                @db.execute("insert into sites values(?, ?, ?)", nil, site_uri.to_s, at.to_s) # I think I can get the row back w/o another query
                cached_site = @db.get_first_row("select * from sites where url = :url", :url => site_uri.to_s)
            end
            @site_id = cached_site[0]
        end

        def has?(uri)
            !@db.get_first_row("select * from urls where url = :url", :url => uri.to_s).nil?
        end
        
        def add(uri, checksum)
            write(uri, checksum)
        end

        def get(uri)
           cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
           [cached_url[0].to_i, URI.parse(cached_url[1]), cached_url[2]] if cached_url
        end

        def delete(uri)
            cached_url = get(uri)
            if cached_url
                @db.execute("select * from site_urls where url_id = :url_id", :url_id => cached_url[0])
                @db.execute("delete from site_urls where site_id = :site_id and url_id = :url_id", :site_id => @site_id, :url_id => cached_url[0])
                remaining_site_references  = @db.get_first_row("select * from site_urls where url_id = :url_id", :url_id => cached_url[0])
                @db.execute("delete from urls where id = :id", :id => cached_url[0]) unless remaining_site_references
            end
        end

    private
        def write(uri, checksum)
            cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
            unless cached_url
                @db.execute("insert into urls values(?, ?, ?)", nil, uri.to_s, checksum)
                cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s) # Do I need to do - this, I think I can get the info from above
            end
            site_url = @db.get_first_row("select * from site_urls where site_id = :site_id and url_id = :url_id", :site_id => @site_id, :url_id => cached_url[0])
            @db.execute("insert into site_urls values(?, ?, ?)", nil, @site_id, cached_url[0]) unless site_url
        end

        def create_tables()
            @db.execute("create table if not exists sites(id integer primary key autoincrement, url string, at string)")
            @db.execute("create table if not exists urls(id integer primary key autoincrement, url string, checksum string)")
            @db.execute("create table if not exists site_urls(id integer primary key autoincrement, site_id integer, url_id integer)")
        end
    end
end
