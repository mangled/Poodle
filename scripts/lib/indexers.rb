#!/usr/bin/env ruby
require 'rubygems'
require 'uri'
require 'tempfile'
require 'pathname'
require 'cgi'
require 'digest/md5'

module Poodle
    class SolrIndexer
    
        def initialize(params)
            @solr = params[:solr]
            @log = params[:log]
        end
    
        def index(uri, content, title, checksum)
            begin
                temp_file, current_checksum = new_temp(content)
                if current_checksum != checksum
                    checksum = current_checksum
                    id = unique_id(uri)
                    if title
                        solr_url = URI.join(@solr.to_s, "update/extract?literal.id=#{id}&literal.crawled_title=#{CGI.escape(title)}&commit=true&literal.url=#{CGI.escape(uri.to_s)}")
                    else
                        solr_url = URI.join(@solr.to_s, "update/extract?literal.id=#{id}&commit=true&literal.url=#{CGI.escape(uri.to_s)}")
                    end
                    solr_args = "--silent \"#{solr_url}\" -H '#{CGI.escape("Content-type:" + content.content_type)}' -F \"myfile=@#{Pathname.new(temp_file.path)}\""
                    @log.warn("#{uri} Curl failed") unless SolrIndexer.curl(solr_args)
                else
                    @log.info("Skipped indexing as checksum hasn't changed #{uri}")
                end
            ensure
                temp_file.unlink() if temp_file
            end
            checksum
        end

        def new_temp(content)
            digest = Digest::MD5.new
            temp_file = Tempfile.new("content")
            temp_file.binmode
            content.readlines.each do |line|
                temp_file << line
                digest.update(line)
            end
            temp_file.flush()
            temp_file.close()
            [temp_file, digest.hexdigest]
        end

        def unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end

        # This is here to simplify unit-testing, couldn't be bothered overriding back-tic's
        def SolrIndexer.curl(s)
            `curl #{s}`
            $?.success?
        end
    end
end