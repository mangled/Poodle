#!/usr/bin/env ruby
#
# Some **simple** crawler tests - Not **exhaustive** but just enough to give some confidence!
# They are a bit messy and need some cleaning - Sorry...

require 'rubygems'
require 'test/unit'
require 'uri'
require 'mocha'
require 'fakeweb'
require 'set'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'crawler'
require 'synchronization'

# Note: The code started out as one monolithic chunk, this test effectively covered
# everything. As the code has been refactored more tests have been produced which
# overlap those here. Basically a number of these tests can be removed (carefully!)
module Poodle
    class TestWeb < Test::Unit::TestCase
    
        class FakeIndexer
            attr_accessor :items, :expectations
    
            def initialize(expectations = nil)
              @items = []
              @expectations = expectations
            end
    
            def index(uri, content, title)
                @items << { :uri => uri, :content => content, :title => title }
                @expectations.shift.call(@items[-1]) if @expectations
            end
        end
    
        def setup
            @log = mock()
            @solr = 'http://localhost:1234/'
            FakeWeb.allow_net_connect = false
        end
        
        def test_crawl_all
            check_crawler(graph_basic())
            check_crawler(graph_basic(), [], false)
            check_crawler(graph_basic())
        end
        
        def test_crawl_with_ignore
            check_crawler(graph_basic(), ['g.html'])
        end
        
        def test_same_site
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
            @log.expects(:warn).once.with('Skipping as host differs http://www.bar.com/').returns(nil)
            
            url1 = 'http://www.foo.com/foo.html'
            url2 = 'http://www.bar.com/'
        
            add_expect_uri(url1, to_href(url2))
            add_expect_uri(url2)
            assert_equal(1, crawl(url1).length, "Crawled one url")
        end
        
        def test_bad_url
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
            @log.expects(:warn).once.with('Invalid link in page http://www.foo.com/foo.html : bad URI(is not URI?): http://www.foo.com/foo\\bar.html').returns(nil)
            
            url1 = 'http://www.foo.com/foo.html'
            url2 = 'http://www.foo.com/foo\\bar.html'
        
            add_expect_uri(url1, to_href(url2))
            assert_equal(1, crawl(url1).length, "Crawled one url")
        end
        
        def test_skip_fragment
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.html').returns(nil)
            @log.expects(:warn).once.with('Skipped http://www.foo.com/bar.html#3')
        
            url1 = 'http://www.foo.com/foo.html'
            url2 = 'http://www.foo.com/bar.html#3'
        
            add_expect_uri(url1, to_href(url2))
            assert_equal(2, crawl(url1) { |uri| assert(uri.to_s != url2) }.length, "Crawled two urls")
        end
        
        def test_index_no_follow # Only look for links in text/html
            @log.expects(:info).once.with('Indexed http://www.foo.com/foo.stuff').returns(nil)
        
            url = 'http://www.foo.com/foo.stuff'
            url2 = 'http://www.foo.com/bar.html'
        
            add_expect_uri(url, to_href(url2), 'text/unknown')
            assert_equal(1, crawl(url) { |uri| assert(uri.to_s == url) }.length, "Crawled one url")
        end
        
        def test_skip_path
            @log.expects(:warn).once.with('Skipping indexing http://www.foo.com/').returns(nil)
            @log.expects(:info).once.with('Indexed http://www.foo.com/bar.html')
        
            url1 = 'http://www.foo.com/'
            url2 = 'http://www.foo.com/bar.html'
        
            add_expect_uri(url1, to_href(url2))
            add_expect_uri(url2)
            assert_equal(2, crawl(url1) {|uri| assert(uri.to_s != url1) }.length, "Crawled two urls")
        end
    
        def test_referrer
            @log.stubs(:info)
            @log.stubs(:warn)
        
            url1 = URI.parse('http://www.foo.com/foo.html')
            url2 = URI.parse('http://www.foo.com/bar.html')
            url3 = URI.parse('http://www.foo.com/wiz/pop/')
            url4 = URI.parse('http://www.foo.com/foo.pdf')
    
            add_expect_uri(url1.to_s, to_href(url2.to_s))
            add_expect_uri(url2.to_s, to_href(url3.to_s))
            add_expect_uri(url3.to_s, to_href(url4.to_s))
            add_expect_uri(url4.to_s)
    
            p = params(url1.to_s)
            analyzer = mock()
            analyzer.expects(:extract_links).with(url4, url3, nil, p).yields("4", [], nil)
            analyzer.expects(:extract_links).with(url3, url2, nil, p).yields("3", [[ url4, url3 ]], to_href(url4.to_s))
            analyzer.expects(:extract_links).with(url2, url1, nil, p).yields("2", [[ url3, url2 ]], to_href(url3.to_s))
            analyzer.expects(:extract_links).with(url1, "",   nil, p).yields("1", [[ url2, url1 ]], to_href(url2.to_s))
    
            links = crawl(url1.to_s, nil, analyzer)
            assert_equal(4, links.length, "Crawled four urls")
        end
        
        def test_relative_url_normalized
            @log.stubs(:info)
            @log.stubs(:warn)
        
            root = 'http://www.woo.com/'
            urls = ['woo.html', 'bar.html', 'woo/woo.html', 'boing.html', '../twang.html']
        
            add_expect_uri(root + urls[0], to_href(urls[1]))
            add_expect_uri(root + urls[1], to_href(urls[2]))
            add_expect_uri(root + urls[2], to_href(urls[3]))
            add_expect_uri(root + 'woo/boing.html', to_href(urls[4]))
            add_expect_uri(root + 'twang.html')
        
            links = crawl(root + urls[0])
            assert_equal(5, links.length, "Crawled five urls")
        end
        
        def test_should_analyze
            assert_equal false, Crawler.should_analyze?(URI.parse("file:/foo.bar"), [], [])
            assert_equal false, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.bar#1"), [], [])
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.bar"), [], [])
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/"), [], [])
        
            assert_equal false, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.bar"), ['.bar'], [])
            assert_equal false, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.BaR"), ['.bar'], [])
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.bar"), ['.doc'], [])
        
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.bar"), [], ['.bar'])
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.BaR"), [], ['.bar'])
            assert_equal false, Crawler.should_analyze?(URI.parse("http://www.foo.com/foo.wiz"), [], ['.bar'])
            assert_equal true, Crawler.should_analyze?(URI.parse("http://www.foo.com/"), [], ['.doc'])
            assert_equal false, Crawler.should_analyze?(URI.parse("http://www.foo.com"), [], ['.doc'])
        end

        # Helpers
        #########
    
        def params(url)
            { :url => URI.parse(url), :ignore => [], :accept => [], :index => true, :log => @log, :solr => @solr, :from => "me", :user_agent => "ua" }
        end
        
        def crawl(url, indexer = FakeIndexer.new, analyzer = Poodle::Analyzer.new)
            queue = Poodle::WorkQueue.new([URI.parse(url), ""])
            Crawler.crawl(params(url), indexer, analyzer, queue)
            queue.processed
        end

        def add_expect_uri(url, body = 'Hello world', content_type = "text/html", status = ["200", "OK"])
            FakeWeb.register_uri(:get, url, :body => body, :content_type => content_type, :status => status)
        end
        
        def to_href(url)
            "<a href=\"" + url + "\">Bar</a>"
        end
    
        # Silly, bloated test that needs re-factoring!!!
        ################################################
    
        def check_crawler(graph, ignore = [], index = true)
            # Not checking logging information so ignore
            @log.stubs(:info)
            @log.stubs(:warn)
    
            urll = 'http://www.foo.com/a.html'
    
            urls, pages = make_web(URI.parse(urll), :a, graph)
    
            error_pages = {}
            pages.each do |url, page|
                FakeWeb.register_uri(
                    :get, url, :body => page[:body], :content_type => page[:content_type], :status => page[:status]
                )
                error_pages[url.to_s] = page if page[:status][0] != "200"
            end
    
            p = params(urll).merge({:ignore => ignore, :index => index})
    
            indexer = FakeIndexer.new
            queue = Poodle::WorkQueue.new([p[:url], ""])
            Crawler.crawl(p, indexer, Poodle::Analyzer.new, queue)
            links = queue.processed
    
            indexer.items.each do |item|
                assert(!error_pages.keys.include?(item[:uri].to_s))
                assert_nil item[:title]
                assert(urls.delete? item[:uri].to_s)
                assert_equal(item[:content].content_type, pages[item[:uri].to_s][:content_type])
                assert_equal("ua", FakeWeb.last_request["User-Agent"])
                assert_equal("me", FakeWeb.last_request["From"])
            end
    
            if ignore.empty?
                # Always returns total links seen, even if they generate an error
                assert_equal(pages.keys.length, links.length) if index
            else
                urls.each do |url|
                    assert(ignore.any? {|reg| url.to_s =~ /#{Regexp.quote(reg)}/}) unless error_pages.keys.include?(url.to_s)
                end
            end
            assert_equal(pages.length, links.length, "Crawled count")
        end
    
        def graph_basic
            [
                {
                    :d => {:content_type => "text/html", :status => ["404", "Not Found"]}
                },
                {
                    :a => [ :b, :c ],
                    :b => [ :d, :e, :a ],
                    :c => [ :f ],
                    :d => [],
                    :e => [ :g, :f ],
                    :f => [],
                    :g => []
                }
            ]
        end
    
        # Relative/non-relative test (add later when code is tidier)
        def make_web(root, initial_node, graph)
            pages = {}
            urls = Set.new
    
            info, tree = graph
    
            rem = [initial_node]
            while !rem.empty?
                foo = []
                rem.each do |node|
                    url = root.merge("/#{node}.html")
                    body = "<head><title>#{tree[node]}</title></head>"
                    tree[node].each do |child|
                        body += "<body>http://foo/bar.html <a href=\"/#{child}.html\">#{child}</a></body>"
                        foo.insert(-1, child) unless pages.has_key?(url.to_s)
                    end
                    content_type = "text/html"
                    status = ["200", "OK"]
                    if info.has_key? node
                        content_type = info[node][:content_type]
                        status = info[node][:status]
                    end
                    pages[url.to_s] = {:body => body, :content_type => content_type, :status => status}
                    urls.add(root.merge("/#{node}.html").to_s)
                end
                rem = foo
            end
            [urls, pages]
        end
    end
end

