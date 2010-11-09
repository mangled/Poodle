#!/usr/bin/env ruby
require 'rubygems'
require 'logger'
require 'thwait'
require 'sqlite3'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'web'
require 'indexers'
require 'cache'
require 'synchronization'
require 'options'

module Poodle
    def Poodle.crawl(options, cache, started_at, logger)

        options[:log] = logger
    
        logger.info("Root URL: #{options[:url]}")
        logger.info("Solr URL: #{options[:solr]}")
        logger.info("Ignoring: #{options[:ignore].join(',')}")
        logger.info("Accepting: #{options[:accept].join(',')}")
        logger.info("Threads: #{options[:threads]}")
        logger.info("Minimum seconds between fetch: #{options[:wait]}")
        logger.info("Indexing: #{options[:index]}")

        urls_to_crawl = WorkQueue.new([options[:url], ""])
        trap("INT") { urls_to_crawl.kill(true) }

        cache.populate(urls_to_crawl)

        workers = ThreadsWait.new
        1.upto(options[:threads]) do |i|
            workers.join_nowait(
                Thread.new do
                    Crawler.crawl(options, SolrIndexer.new(options), Analyzer.new, urls_to_crawl)
                end
            )
        end
        workers.all_waits
        
        # There are smarter ways or finding unused items!
        processed = urls_to_crawl.processed
        cache.delete
        cache.add(processed)

        logger.info("Crawled #{processed.length} url(s) in #{(Time.now - started_at)/60.0} minutes")
    end
end

if __FILE__ == $0
    started_at = Time.now

    options =
    begin
        Poodle::CrawlerOptions.get_options(ARGV)
    rescue RuntimeError => e
        puts e
        exit(-1)
    end

    logger = if options[:logname]
        Logger.new(options[:logname], 'daily')
    else
        Logger.new(STDOUT)
    end
    
    cache = Poodle::Cache.from_path(options[:url], started_at, ".")

    begin
        Poodle::crawl(options, cache, started_at, logger)
    rescue Exception => e
        puts "Unhandled exception: #{e}"
        logger.fatal("Unhandled exception: #{e}")
        exit(-1)
    end
end
