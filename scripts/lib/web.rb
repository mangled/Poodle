#!/usr/bin/env ruby
require 'rubygems'
require 'uri'
require 'digest/md5'
require 'set'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'analyzer'
require 'synchronization'
require 'indexers'

module Poodle
    class Crawler

        def Crawler.crawl(params, indexer = nil, analyzer = Analyzer.new, urls = WorkQueue.new)
            begin
                urls.remove do |item|
                    uri, referer = item
                    if Crawler.should_analyze?(uri, params[:ignore], params[:accept])
                        sleep(params[:wait]) if params[:wait]
                        Crawler.analyze_and_index(uri, referer, params, urls, indexer, analyzer)
                    else
                        params[:log].warn("Skipped #{uri}") unless params[:quiet]
                    end
                end
            end while !urls.done?
            urls.processed
        end

        def Crawler.analyze_and_index(uri, referer, params, urls, indexer, analyzer)
            begin
                title, new_links, content = analyzer.extract_links(uri, referer, params)
                new_links.each do |link|
                    urls.add(link[0], link[1])
                end

                if Crawler.should_index?(uri, (params[:index] and indexer))
                    uri_id = Crawler.unique_id(uri)
                    indexer.index({ :uri => uri, :content => content, :id => uri_id, :title => title })
                    params[:log].info("Indexed #{uri}")
                else
                    params[:log].warn("Skipping indexing #{uri}")  unless params[:quiet]
                end
            rescue AnalyzerError => e
            end
        end
    
        def Crawler.unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end
        
        def Crawler.should_analyze?(uri, ignore, accept)
            return false if uri.scheme != 'http' or uri.fragment
            if accept.empty? # Yuk, use nils?
                return false if ignore.any? {|reg| uri.to_s =~ /#{Regexp.quote(reg)}/i}
                return true
            else
                return true if accept.any? {|reg| uri.to_s =~ /#{Regexp.quote(reg)}/i}
                return Crawler.is_directory?(uri)
            end
        end

        def Crawler.should_index?(uri, indexing_enabled)
            indexing_enabled and !Crawler.is_directory?(uri)
        end
        
        def Crawler.is_directory?(uri)
            /\/$/.match(uri.to_s) ? true : false
        end
    end
end
