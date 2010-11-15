#!/usr/bin/env ruby
require 'rubygems'
require 'test/unit'
require 'mocha'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'crawler'
require 'cache'
require 'options'

$:.unshift File.join(File.dirname(__FILE__), ".")
require 'helpers'

module Poodle
  class TestCrawler < Test::Unit::TestCase

    # This is very minimal, just checks gross wiring mistakes in "main" early!
    def test_crawl_default_options
      options = CrawlerOptions.default

      options[:url] = UrlUtilities::random_url()
      options[:solr] = UrlUtilities::random_url()

      logger = mock()
      logger.stubs(:info)

      queue = mock()
      queue.expects(:add).with(options[:url], "", nil)
      queue.expects(:processed).returns(["hello"])

      WorkQueue.expects(:new).with(nil).returns(queue)
      
      Crawler.expects(:crawl).returns(nil)

      Cache.expects(:from_path).never

      started_at = Time.parse("2000-01-01")
      
      Poodle.crawl(options, started_at, logger)
    end

    def test_crawl_cache_enabled
      options = CrawlerOptions.default
      options[:cache_enabled] = true
    
      options[:url] = UrlUtilities::random_url()
      options[:solr] = UrlUtilities::random_url()
    
      logger = mock()
      logger.stubs(:info)
    
      queue = mock()
      queue.expects(:add).with(options[:url], "", nil)
      queue.expects(:processed).returns(["hello"])
    
      WorkQueue.expects(:new).with(nil).returns(queue)
      
      Crawler.expects(:crawl).returns(nil)
    
      started_at = Time.parse("2000-01-01")
    
      cache = mock()
      cache.expects(:populate)
      cache.expects(:delete)
      cache.expects(:add).with(["hello"])
      Cache.expects(:from_path).once.returns(cache)
      
      Poodle.crawl(options, started_at, logger)
    end

  end
end
