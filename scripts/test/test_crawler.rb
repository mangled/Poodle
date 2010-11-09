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
    def test_crawl
      options = CrawlerOptions.default

      options[:url] = UrlUtilities::random_url()
      options[:solr] = UrlUtilities::random_url()

      logger = mock()
      logger.stubs(:info)

      queue = mock()
      queue.expects("last_crawled_site_at=").with(nil)
      queue.expects(:processed).returns(["hello"])

      WorkQueue.expects(:new).with([options[:url], ""]).returns(queue)
      Crawler.expects(:crawl).returns(nil)

      cache = Cache.new(options[:url], Time.parse("2000-01-01"))
      cache.expects(:delete)
      cache.expects(:add).with(["hello"])
      
      Poodle.crawl(options, cache, logger)
    end

  end
end
