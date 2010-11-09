#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'
require 'fakeweb'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'analyzer'

module Poodle
    class TestAnalyzer < Test::Unit::TestCase
    
        # Test different sites, poor uri's, relative url logic (remove from crawler then)
        # Title extraction code, link scheme...
    
        def setup
            @log = mock()
            FakeWeb.allow_net_connect = false
        end
    
        def test_analyze_only_text_html
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", to_href("http://www.foo.com/hello.html"), 'foo/bar')
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal [], new_links
                assert_equal [to_href("http://www.foo.com/hello.html")], content.readlines
            end
        end
    
        def test_with_link
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", to_href("http://www.foo.com/hello.html"))
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal([ [URI.parse("http://www.foo.com/hello.html"), URI.parse("http://www.foo.com/")] ], new_links)
                assert_equal [to_href("http://www.foo.com/hello.html")], content.readlines
            end
        end

        def test_no_cross_site
            @log.expects(:warn).once.with('Skipping as host differs http://www.bar.com/hello.html')
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", to_href("http://www.bar.com/hello.html"))
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal([], new_links)
                assert_equal [to_href("http://www.bar.com/hello.html")], content.readlines
            end
        end

        def test_follow_only_http_links
            @log.expects(:warn).once.with('Skipping as non-http file://hello.html')
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", to_href("file://hello.html"))
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal([], new_links)
                assert_equal [to_href("file://hello.html")], content.readlines
            end
        end
    
        def test_bad_uri
            @log.expects(:warn).once.with('Invalid link in page http://www.foo.com/ : bad URI(is not URI?): :bar:foo')
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", to_href(":bar:foo"))
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal([], new_links)
                assert_equal [to_href(":bar:foo")], content.readlines
            end
        end
    
        def test_no_links
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/")
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "peter pan", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
                assert_equal([], new_links)
                assert_equal ['Hello world'], content.readlines
            end
        end
    
        def test_head_title
            body = '<html><head><title>Fish Head!</title></head></html>'
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", body)
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "eel man", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
            end
    
            # Only store if the strip worked
            p.merge!({ :title_strip => 'Tree!'})
            add_expect_uri("http://www.foo.com/", body)
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "eel man", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
            end
            
            p.merge!({ :title_strip => 'Head!'})
            add_expect_uri("http://www.foo.com/", body)
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "eel man", p) do |crawled_title, new_links, content|
                assert_equal 'Fish', crawled_title
            end
        end
    
        def test_ideas_title
            body = '<div class="contentheading bh_suggestiontitle">Womble</div>'
    
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", body)

            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "eel man", p) do |crawled_title, new_links, content|
                assert_equal 'Womble', crawled_title
            end

            add_expect_uri("http://www.foo.com/", body + body)
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "fish man", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
            end
        end
    
        def test_blog_title
            body = '<div class="post-title"><h1><a href="foo">Womble</a></h1></div>'
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/", body)

            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "squid man", p) do |crawled_title, new_links, content|
                assert_equal 'Womble', crawled_title
            end
            
            add_expect_uri("http://www.foo.com/", body + body)
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/"), "squid man", p) do |crawled_title, new_links, content|
                assert_equal nil, crawled_title
            end
        end
    
        def test_content_not_changed
            @log.expects(:info).once.with('Content hasn\'t changed since last crawl http://www.foo.com/bar.html')
            p = { :log => @log, :user_agent => "007", :from => "mars" }
            add_expect_uri("http://www.foo.com/bar.html", "hello", "text/html", ["304", "Not Modified"])
            Analyzer.new().extract_links(URI.parse("http://www.foo.com/bar.html"), "peter pan", p) do |content|
                assert_equal [], content
            end
        end

        # Helpers
        #########
    
        def add_expect_uri(url, body = 'Hello world', content_type = "text/html", status = ["200", "OK"])
            FakeWeb.register_uri(:get, url, :body => body, :content_type => content_type, :status => status)
        end
        
        def to_href(url)
            "<a href=\"" + url + "\">Bar</a>"
        end
    end
end