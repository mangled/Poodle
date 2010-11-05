#!/usr/bin/env ruby
require 'rubygems'
require 'logger'
require 'thwait'
require 'sqlite3'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'web'
require 'indexers'
require 'options'

if __FILE__ == $0
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

    options[:log] = logger

    logger.info("Root URL: #{options[:url]}")
    logger.info("Solr URL: #{options[:solr]}")
    logger.info("Ignoring: #{options[:ignore].join(',')}")
    logger.info("Accepting: #{options[:accept].join(',')}")
    logger.info("Threads: #{options[:threads]}")
    logger.info("Minimum seconds between fetch: #{options[:wait]}")
    logger.info("Indexing: #{options[:index]}")

    begin
        urls_to_crawl = Poodle::WorkQueue.new([options[:url], ""])
        trap("INT") { urls_to_crawl.kill(true) }
        crawled_urls = Poodle::CrawledSet.new

        started = Time.now

        workers = ThreadsWait.new
        1.upto(options[:threads]) do |i|
            workers.join_nowait(
                Thread.new do
                    Poodle::Crawler.crawl(options, Poodle::SolrIndexer.new(options), Poodle::Analyzer.new, urls_to_crawl, crawled_urls)
                end
            )
        end
        workers.all_waits

        logger.info("Crawled #{crawled_urls.length} url(s) in #{(Time.now - started)/60.0} minutes")
    rescue Exception => e
        puts "Unhandled exception: #{e}"
        logger.fatal("Unhandled exception: #{e}")
        exit(-1)
    end
end
