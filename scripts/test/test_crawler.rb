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

class TestCrawler < Test::Unit::TestCase

    def setup
        @log = mock()
        @solr = 'http://localhost:1234/'
        FakeWeb.allow_net_connect = false
    end

    def test_crawl_all
        check_crawler(graph_basic())
        check_crawler(graph_basic(), [], false)
        check_crawler(graph_basic(), [], false, 2)
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
        @log.expects(:warn).once.with('Skipping indexing as path URL http://www.foo.com/').returns(nil)
        @log.expects(:info).once.with('Indexed http://www.foo.com/bar.html')
    
        url1 = 'http://www.foo.com/'
        url2 = 'http://www.foo.com/bar.html'

        add_expect_uri(url1, to_href(url2))
        add_expect_uri(url2)
        assert_equal(2, crawl(url1) {|uri| assert(uri.to_s != url1) }.length, "Crawled two urls")
    end

    def test_referrer
        @log.stubs(:info)
    
        url1 = 'http://www.foo.com/foo.html'
        url2 = 'http://www.foo.com/bar.html'
        url3 = 'http://www.foo.com/wib.html'

        add_expect_uri(url1, to_href(url2))
        add_expect_uri(url2, to_href(url3))
        add_expect_uri(url3)
        links = Crawler.crawl(params(url1)) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert_equal(FakeWeb.last_request["Referer"], "") if uri.to_s == url1
            assert_equal(FakeWeb.last_request["Referer"], url1) if uri.to_s == url2
            assert_equal(FakeWeb.last_request["Referer"], url2) if uri.to_s == url3
        end
        assert_equal(3, links.length, "Crawled three urls")
    end

    def test_title
        @log.stubs(:info)
        url = 'http://www.foo.com/foo.html'
        add_expect_uri(url, "foo")
        Crawler.crawl(params(url)) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert_nil title
        end
        # Strip not set
        add_expect_uri(url, "<head><title>squid man</title></head>")
        Crawler.crawl(params(url)) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert_nil title
        end
        # Strip set no title change
        add_expect_uri(url, "<head><title>squid man - Foo Wiki</title></head>")
            Crawler.crawl(params(url).merge({ :title_strip => 'treacle' })) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert_nil title
        end
        # Strip set and title changed
        add_expect_uri(url, "<head><title>squid man - Foo Wiki</title></head>")
            Crawler.crawl(params(url).merge({ :title_strip => '- Foo Wiki' })) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert_equal "squid man", title
        end
    end

    # Grotty - More of a regression test
    def test_solr_crawler_no_title
        @log.expects(:info).at_least_once.with('Indexed http://www.foo.com/foo.html').returns(nil)
        SolrCrawler.expects(:curl).with(regexp_matches(
            /"http:\/\/localhost:1234\/update\/extract\?literal\.id=8a3ca15ba2d277f677b4b2d3598ae57b&commit=true&literal\.url=http%3A%2F%2Fwww.foo.com%2Ffoo.html" -H 'Content-type%3Atext%2Fhtml' -F "myfile=@/
        )).returns(true)
    
        url = 'http://www.foo.com/foo.html'

        add_expect_uri(url)
        assert_equal(1, SolrCrawler.crawl(params(url)).length, "Crawled one url")
    end

    # Grotty - More of a regression test
    def test_solr_crawler_with_title
        @log.expects(:info).at_least_once.with('Indexed http://www.foo.com/foo.html').returns(nil)
        SolrCrawler.expects(:curl).with(regexp_matches(
            /"http:\/\/localhost:1234\/update\/extract\?literal\.id=8a3ca15ba2d277f677b4b2d3598ae57b&literal\.crawled_title=squid\+man&commit=true&literal\.url=http%3A%2F%2Fwww.foo.com%2Ffoo.html" -H 'Content-type%3Atext%2Fhtml' -F "myfile=@/
        )).returns(true)
    
        url = 'http://www.foo.com/foo.html'

        add_expect_uri(url, "<head><title>squid man - Foo Wiki</title></head>")
        assert_equal(1, SolrCrawler.crawl(params(url).merge({ :title_strip => '- Foo Wiki' })).length, "Crawled one url")
    end

    # Helpers
    #########

    def params(url)
        { :url => URI.parse(url), :ignore => [], :index => true, :log => @log, :solr => @solr, :from => "me", :user_agent => "ua" }
    end
    
    def crawl(url)
        Crawler.crawl(params(url)) do |uri, content, content_file_path, id, title, depth, solr, log|
            yield uri if block_given?
        end
    end
    
    def add_expect_uri(url, body = 'Hello world', content_type = "text/html", status = ["200", "OK"])
        FakeWeb.register_uri(:get, url, :body => body, :content_type => content_type, :status => status)
    end
    
    def to_href(url)
        "<a href=\"" + url + "\">Bar</a>"
    end

    # Silly, bloated test that needs re-factoring!!!
    ################################################

    def check_crawler(graph, ignore = [], index = true, maxdepth = nil)
        # Not checking logging information so ignore
        @log.stubs(:info)
        @log.stubs(:warn)

        urll = 'http://www.foo.com/a.html'

        urls, pages = make_web(URI.parse(urll), :a, graph, maxdepth)

        error_pages = {}
        pages.each do |url, page|
            FakeWeb.register_uri(
                :get, url, :body => page[:body], :content_type => page[:content_type], :status => page[:status]
            )
            error_pages[url.to_s] = page if page[:status][0] != "200"
        end

        ids = Set.new
        cur_depth = 0
        p = params(urll).merge({ :depth => maxdepth, :ignore => ignore, :index => index})
        links = Crawler.crawl(p) do |uri, content, content_file_path, id, title, depth, solr, log|
            assert(!error_pages.keys.include?(uri.to_s))
            assert(!ids.include?(id))
            ids.add(id)
            assert_nil title
            assert_equal(solr, solr)
            assert(urls.delete? uri.to_s)
            assert(File.open(content_file_path, "rb").read, pages[uri.to_s])
            assert_equal(content.content_type, pages[uri.to_s][:content_type])
            assert(depth - cur_depth < 2)
            assert(depth <= maxdepth) if maxdepth
            cur_depth = depth
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
    def make_web(root, initial_node, graph, maxdepth)
        pages = {}
        depth = 0
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
            break if depth == maxdepth
            depth += 1
        end
        [urls, pages]
    end
end

