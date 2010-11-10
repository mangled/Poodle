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
                    uri, referer, checksum = item
                    if Crawler.should_analyze?(uri, params[:ignore], params[:accept])
                        sleep(params[:wait]) if params[:wait]
                        checksum = Crawler.analyze_and_index(uri, referer, checksum, params, urls, indexer, analyzer)
                    else
                        params[:log].warn("Skipped #{uri}") unless params[:quiet]
                    end
                    checksum
                end
            end while !urls.done?
            urls.processed
        end

        def Crawler.analyze_and_index(uri, referer, last_checksum, params, urls, indexer, analyzer)
            checksum = nil
            begin
                analyzer.extract_links(uri, referer, urls.last_crawled_site_at, params) do |title, new_links, content|

                    # Note: because links are added here they will be filtered on the current accept rules
                    # (on the parent) if these cmd line options change then the database is basically invalid?
                    new_links.each {|link| urls.add(link[0], link[1], nil) }

                    # THIS NEEDS TIDYING AND A TEST OR TWO ADDED i.e. no tests exist for content checksum checks
                    checksum = Crawler.checksum(content) # This should be in the indexer?

                    if Crawler.should_index?(uri, (params[:index] and indexer)) and last_checksum != checksum
                        uri_id = Crawler.unique_id(uri) # Put this in the indexer and stop using a hash to pass stuff like this!
                        indexer.index({ :uri => uri, :content => content, :id => uri_id, :title => title })
                        params[:log].info("Indexed #{uri}")
                    else
                        params[:log].warn("Skipping indexing #{uri}")  unless params[:quiet]
                    end
                end
            rescue AnalyzerError => e
                # Analyzer will have logged
            end
            checksum
        end

        def Crawler.unique_id(uri)
            digest = Digest::MD5.new().update(uri.normalize().to_s)
            digest.hexdigest
        end
        
        def Crawler.checksum(content)
            content.rewind if content.respond_to?(:rewind)
            digest = Digest::MD5.new()
            content.readlines.each do |line|
                digest.update(line.to_s)
            end
            content.rewind if content.respond_to?(:rewind)
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
