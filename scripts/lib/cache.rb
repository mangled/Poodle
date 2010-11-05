#!/usr/bin/env ruby
require 'sqlite3'

module Poodle
    class Cache
    
      def initialize()
        #existed = File.exists?(path)
        @db = SQLite3::Database.new(":memory:")
        create_tables #unless existed
      end

      def has?(uri)
        !@db.get_first_row("select * from urls where url = :url", :url => uri.to_s).nil?
      end
    
      def get(uri)
        row = @db.get_first_row("select * from urls where url = ?", uri.to_s)
        unless row
          @db.execute("insert into urls values(?, ?)", nil, uri.to_s)
          row = @db.get_first_row("select * from urls where url = ?", uri.to_s)
        end
        row
      end
      
      def links_from(uri)
          links = []
          if has?(uri) # There is a more effecient sql statement for this join table
              uri_id = get(uri)[0]
              @db.execute("select * from urllinks where url = :url", :url => uri_id) do |link|
                row = @db.get_first_row("select * from urls where url = ?", link[1])
                if row
                    links << URI.parse(link[1])
                end # ELSE KILL BOGUS?
              end
          end
          links
      end
    
      def add(uri, links = [])
        uri_id = get(uri)[0]
        links.each do |link|
          link_id = get(link)[0]
          row = @db.get_first_row("select * from urllinks where url = :url and link = :link", :url => uri_id, :link => link_id)
          @db.execute("insert into urllinks values(:url, :link)", :url => uri_id, :link => link_id) unless row
        end
      end
    
      def delete(uri)
        if has?(uri)
          uri_id = get(uri)[0]
          puts "deleting #{uri} #{uri_id}"
          @db.execute("delete from urls where id = :id", :id => uri_id)
          @db.execute("delete from urllinks where url = :url or link = :link", :url => uri_id, :link => uri_id)
        end
      end
    
      def create_tables()
        @db.execute("create table urls(id integer primary key autoincrement, url string)")
        @db.execute("create table urllinks(url integer, link integer)")
      end
      
      def to_s
        s = ""
        s << "Urls Table\n"
        @db.execute("select * from urls").each {|row| s << row.join(" ") + "\n" }
        s << "\n"
        s << "Url Links Table\n"
        @db.execute("select * from urllinks").each {|row| s << row.join(" ") + "\n" }
        s
      end
    end
end
