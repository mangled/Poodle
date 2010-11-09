#!/usr/bin/env ruby
require 'sqlite3'
require 'uri'

module Poodle

    class Cache
        
        attr_accessor :last_crawled_site_at

        def initialize(site_uri, at, db = SQLite3::Database.new(":memory:"))
            @db = db
            create_tables()
            update(site_uri, at)
        end
        
        def Cache.from_path(site_uri, at, path, delete_old = false)
            filename = File.join(path, site_uri.host.gsub(/\./, '_'))
            File.delete(filename) if delete_old and File.exists?(filename)
            db = SQLite3::Database.new(filename)
            Cache.new(site_uri, at, db)
        end
        
        def populate(container)
            @db.execute("select * from urls order by id") do |item|
                container.add(URI.parse(item[1]), URI.parse(item[2]))
            end
            # YUK!!!
            container.last_crawled_site_at = last_crawled_site_at
        end

        def add(items)
            @db.transaction do |db|
                items.each do |uri, referer|
                    cached_url = db.get_first_row("select * from urls where url = :url", :url => uri.to_s)
                    unless cached_url
                        db.execute("insert into urls values(?, ?, ?)", nil, uri.to_s, referer.to_s)
                    end
                end
            end
        end

        def delete
            @db.execute("delete from urls")
        end

    private

        def create_tables()
            @db.execute("create table if not exists sites(id integer primary key autoincrement, url string, at string)")
            @db.execute("create table if not exists urls(id integer primary key autoincrement, url string, referer string)")
        end
        
        def update(site_uri, at)
            cached_site = @db.get_first_row("select * from sites where url = :url", :url => site_uri.to_s)
            if cached_site
                @last_crawled_site_at = Time.parse(cached_site[2]) unless cached_site[2].empty?
                @db.execute("update sites set at = :at where id = :id", :at => at.to_s, :id => cached_site[0])
            else
                @db.execute("insert into sites values(?, ?, ?)", nil, site_uri.to_s, at.to_s)
            end
        end
    end
end
