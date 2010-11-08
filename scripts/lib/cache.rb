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
        
        def Cache.from_path(site_uri, at, path, delete_old = false)
            filename = File.join(path, site_uri.host.gsub(/\./, '_'))
            File.delete(filename) if delete_old and File.exists?(filename)
            db = SQLite3::Database.new(filename)
            Cache.new(site_uri, at, db)
        end
        
        def hack_get_db # Want to look at transaction performance
            @db
        end

        # It is about 1/3 quicker if you search by an integer (versus a string)
        # BTW: I modified checksum to be an ingeger and did db.type_translation = true
        # There is an issue wrt referer, i.e. won't mean much to site metrics
        # I don't need title or checksum either for now.
        #
        # USE Transaction in "commit" from workqueue
        def add(uri, referer, title, checksum)
            @semaphore.synchronize do
                cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
                #cached_url = @db.get_first_row("select * from urls where checksum = :checksum", :checksum => checksum)
                unless cached_url
                    @db.execute("insert into urls values(?, ?, ?, ?, ?)", nil, uri.to_s, referer.to_s, title, checksum)
                    #cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
                end
                #cached_url
            end
        end

        #def get(uri) # Not needed - Need a populate queue method and populate from?
        #    @semaphore.synchronize { find(uri) }
        #end
        #
        #def delete(uri) # Not needed - Do need a delete all though
        #    @semaphore.synchronize do
        #        cached_url = find(uri)
        #        @db.execute("delete from urls where id = :id", :id => cached_url[0]) if cached_url
        #    end
        #end

    private

        #def find(uri)
        #    cached_url = @db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
        #    [cached_url[0].to_i, URI.parse(cached_url[1]), URI.parse(cached_url[2]), cached_url[3], cached_url[4]] if cached_url
        #end

        def create_tables()
            @db.execute("create table if not exists sites(id integer primary key autoincrement, url string, at string)")
            @db.execute("create table if not exists urls(id integer primary key autoincrement, url string, referer string, title string, checksum string)")
        end
    end

end
