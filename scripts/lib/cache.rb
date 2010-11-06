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
            @done = false
        end

        # Still think this sould be generated from the cache i.e. new_work_queue() returns a class WorkQueue which does the following.
        # Need done and kill! might want to pull this out into a cache work queue? remove might be better there too? Just need
        # an execute(cmd) method on this? add() passes through? workqueue should probably define a last_crawl as always nil?
        # Actually all I need to-do is remove the work-queue, it is basically dead
        # This class needs synchronisation objects though
        #
        # analyze()
        # add new urls (empty (and so is content) if not modified)
        #
        # rescue xxx => delete url from cache
        def remove # RENAME TO next, add synch.
            unless @done
                @current_id = @current_id || 0
                if @current_id == 0
                    cmd = "select * from urls where id > :id order by id"
                else
                    cmd = "select * from urls where id >= :id order by id" if @current_id == 0
                end
                cached_url = @db.get_first_row("select * from urls where id > :id order by id", :id => @current_id)
                if cached_url
                    @current_id = cached_url[0]
                    yield [@current_id.to_i, URI.parse(cached_url[1]), URI.parse(cached_url[2]), cached_url[3], cached_url[4]]
                else
                    @done = true
                    nil
                end
            end
        end

        def has?(uri)
            !@db.get_first_row("select * from urls where url = :url", :url => uri.to_s).nil?
        end
        
        def add(uri, referer, title, checksum)
            cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
            unless cached_url
                @db.execute("insert into urls values(?, ?, ?, ?, ?)", nil, uri.to_s, referer.to_s, title, checksum)
                cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s) # Do I need to do - this, I think I can get the info from above
            end
            site_url = @db.get_first_row("select * from site_urls where site_id = :site_id and url_id = :url_id", :site_id => @site_id, :url_id => cached_url[0])
            @db.execute("insert into site_urls values(?, ?, ?)", nil, @site_id, cached_url[0]) unless site_url
        end

        def get(uri)
           cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
           [cached_url[0].to_i, URI.parse(cached_url[1]), URI.parse(cached_url[2]), cached_url[3], cached_url[4]] if cached_url
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

        def create_tables()
            @db.execute("create table if not exists sites(id integer primary key autoincrement, url string, at string)")
            @db.execute("create table if not exists urls(id integer primary key autoincrement, url string, referer string, title string, checksum string)")
            @db.execute("create table if not exists site_urls(id integer primary key autoincrement, site_id integer, url_id integer)")
        end
    end
end
