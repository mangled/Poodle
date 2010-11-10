#!/usr/bin/env ruby
require 'rubygems'
require 'uri'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'analyzer'
require 'synchronization'
require 'indexers'

module Poodle
    class Crawler

        def Crawler.crawl(params, indexer = nil, analyzer = Analyzer.new, urls = WorkQueue.new)
            begin
                urls.remove do |uri, referer, checksum|
                    if Crawler.should_analyze?(uri, params[:ignore], params[:accept])
                        sleep(params[:wait]) if params[:wait]
                        checksum = Crawler.analyze_and_index(uri, referer, checksum, params, urls, indexer, analyzer)
                    else
                        params[:log].warn("Skipped #{uri}") unless params[:quiet]
                    end
                    [uri, referer, checksum] # At some point catch here and return nil => drop uri
                end
            end while !urls.done?
        end

        def Crawler.analyze_and_index(uri, referer, checksum, params, urls, indexer, analyzer)
            begin
                analyzer.extract_links(uri, referer, urls.last_crawled_site_at, params) do |title, new_links, content|
                    # Note: because links are added here they will be filtered on the current accept rules
                    # (on the parent) if these cmd line options change then the database is basically invalid?
                    new_links.each {|link| urls.add(link[0], link[1], nil) }

                    if Crawler.should_index?(uri, (params[:index] and indexer))
                        checksum = indexer.index(uri, content, title, checksum)
                        params[:log].info("Indexed #{uri}") # This should be in the indexer?
                    else
                        params[:log].warn("Skipping indexing #{uri}")  unless params[:quiet]
                    end
                    checksum
                end
            rescue AnalyzerError => e                
            end
            checksum
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
