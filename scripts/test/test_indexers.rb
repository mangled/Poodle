#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'
require 'fakeweb'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'indexers'
require 'web'

module Poodle
    class TestIndexers < Test::Unit::TestCase
    
        class FakeContent
            attr_accessor :content_type
            def initialize(type, body)
                @content_type = type
                @body = StringIO.new(body)
            end
            def readlines()
                @body.readlines
            end
        end
    
        def setup
            @log = mock()
            @solr = 'http://localhost:1234/'
            FakeWeb.allow_net_connect = false
        end
    
        # Grotty - More of a regression test
        def test_solr_crawler_no_title
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
    
            SolrIndexer.expects(:curl).with(regexp_matches(
                /--silent "http:\/\/localhost:1234\/update\/extract\?literal\.id=8a3ca15ba2d277f677b4b2d3598ae57b&commit=true&literal\.url=http%3A%2F%2Fwww.foo.com%2Ffoo.html" -H 'Content-type%3Atext%2Fhtml' -F "myfile=@/
            )).returns(true)
        
            url = 'http://www.foo.com/foo.html'
        
            add_expect_uri(url)
            assert_equal(1, crawl(params(url)).length, "Crawled one url")
        end
    
        # Grotty - More of a regression test
        def test_solr_crawler_with_title
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
    
            SolrIndexer.expects(:curl).with(regexp_matches(
                /--silent "http:\/\/localhost:1234\/update\/extract\?literal\.id=8a3ca15ba2d277f677b4b2d3598ae57b&literal\.crawled_title=squid\+man&commit=true&literal\.url=http%3A%2F%2Fwww.foo.com%2Ffoo.html" -H 'Content-type%3Atext%2Fhtml' -F "myfile=@/
            )).returns(true)
        
            url = 'http://www.foo.com/foo.html'
        
            add_expect_uri(url, "<head><title>squid man - Foo Wiki</title></head>")
            assert_equal(1, crawl(params(url).merge({ :title_strip => '- Foo Wiki' })).length, "Crawled one url")
        end
        
        def test_curl_fails
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
            @log.expects(:warn).once.with('http://www.foo.com/foo.html Curl failed').returns(nil)
    
            SolrIndexer.expects(:curl).returns(false)
    
            url = 'http://www.foo.com/foo.html'
        
            add_expect_uri(url)
            assert_equal(1, crawl(params(url)).length, "Crawled one url")
        end

        def test_checksum_differs
            solr = URI.parse("http://www.solr.com/")
            indexer = SolrIndexer.new({ :solr => solr, :log => @log })
            SolrIndexer.expects(:curl).returns(true)

            uri = URI.parse("http://www.funk.com/")
            content = FakeContent.new("foo/bar", "this is the body text!")
            assert_equal "1b3c95d45cb56c5f5e397fd850c19acf", indexer.index(uri, content, "titled good stuff", "current checksum is 1234")
        end
        
        def test_checksum_same
            @log.expects(:info).once.with('Skipped indexing as checksum hasn\'t changed http://www.funk.com/')
            solr = URI.parse("http://www.solr.com/")
            indexer = SolrIndexer.new({ :solr => solr, :log => @log })
            SolrIndexer.expects(:curl).never

            uri = URI.parse("http://www.funk.com/")
            content = FakeContent.new("foo/bar", "this is the body text!")
            assert_equal "1b3c95d45cb56c5f5e397fd850c19acf", indexer.index(uri, content, "titled good stuff", "1b3c95d45cb56c5f5e397fd850c19acf")
        end

        # Helpers
        #########
    
        def params(url)
            { :url => URI.parse(url), :ignore => [], :accept => [], :index => true, :log => @log, :solr => @solr, :from => "me", :user_agent => "ua" }
        end
    
        def add_expect_uri(url, body = 'Hello world', content_type = "text/html", status = ["200", "OK"])
            FakeWeb.register_uri(:get, url, :body => body, :content_type => content_type, :status => status)
        end

        def crawl(p)
            queue = Poodle::WorkQueue.new([p[:url], ""])
            Crawler.crawl(p, SolrIndexer.new(p), Poodle::Analyzer.new, queue)
            queue.processed
        end
    end
end
