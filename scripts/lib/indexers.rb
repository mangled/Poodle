#!/usr/bin/env ruby
require 'rubygems'
require 'uri'
require 'tempfile'
require 'pathname'
require 'cgi'

module Poodle
    class SolrIndexer
    
        def initialize(params)
            @solr = params[:solr]
            @log = params[:log]
        end
    
        def index(item)
            # Might be better having a class or struct - for readability?
            temp_file = SolrIndexer.new_temp(item[:content])
            begin
                if item[:title]
                    solr_url = URI.join(@solr.to_s, "update/extract?literal.id=#{item[:id]}&literal.crawled_title=#{CGI.escape(item[:title])}&commit=true&literal.url=#{CGI.escape(item[:uri].to_s)}")
                else
                    solr_url = URI.join(@solr.to_s, "update/extract?literal.id=#{item[:id]}&commit=true&literal.url=#{CGI.escape(item[:uri].to_s)}")
                end
                solr_args = "--silent \"#{solr_url}\" -H '#{CGI.escape("Content-type:" + item[:content].content_type)}' -F \"myfile=@#{Pathname.new(temp_file.path)}\""
                @log.warn("#{item[:uri]} Curl failed") unless SolrIndexer.curl(solr_args)
            ensure
                temp_file.unlink()
            end
        end
        
        def SolrIndexer.new_temp(content)
            temp_file = Tempfile.new("content")
            temp_file.binmode
            temp_file << content.readlines
            temp_file.flush()
            temp_file.close()
            temp_file
        end
    
        # This is here to simplify unit-testing, couldn't be bothered overriding back-tic's
        def SolrIndexer.curl(s)
            `curl #{s}`
            $?.success?
        end
    end
end