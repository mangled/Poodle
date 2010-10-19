#!/usr/bin/env ruby
require 'rubygems'
require 'hpricot'
require 'open-uri'
# The sspi gem is great under windows but causes the fakeweb test gem to barf
# This is a horrid "check" to ensure that neither co-exist and a missing sspi
# is ok (need to use a proxy via the command line). NTLMAPS is good if you
# are trying to authenticate against windows NTLM
begin
    begin
        Module.const_get('FakeWeb')
    rescue NameError
        begin
            require 'win32/sspi/http_proxy_patch'
        rescue LoadError
        end
    end
end
require 'uri'
require 'cgi'
require 'digest/md5'
require 'logger'
require 'set'
require 'tempfile'
require 'pathname'
require 'optparse'


# ContentAnalyzer
#################

class ContentAnalyzer
    def ContentAnalyzer.extract_links(uri, content, params)
        log = params[:log]
        crawled_title = nil
        links = {}

        if content.content_type == 'text/html'
            begin
                # !!! Arg. one of the sites I'm indexing has badly terminated CDATA
                # this needs to be a cmd line option
                doc =
                if params[:yuk]
                    Hpricot(content.readlines.to_s.gsub('/* ]] */', '/* ]]> */'))
                else
                    Hpricot(content)
                end

                doc.search("[@href]").each do |page_url|
                    begin
                        link = URI.parse(page_url.attributes['href'])
                        link = uri.merge(link) if link.relative?
                        # Stay in same site: By design, relax/remove this at your own risk
                        if (uri.host == link.host)
                            links[link] = uri
                        else
                            log.warn("Skipping as host differs #{link}") unless params[:quiet]
                        end
                    rescue URI::InvalidURIError => e
                        log.warn("Invalid link in page #{uri} : #{e}") unless params[:quiet]
                    end
                end
                # This is present to augment Solr's parsing of title's - It should be refactored
                # at the moment is is "hacked" in to improve detection of title's in a word-press
                # blog and a joomla ideas tool.
                # Solr ends up using the page title, which is normally mixed with the blog
                # title and sometimes not representative of the post etc.. There are other issues
                # with parsing blogs that need to be resolved - In another release.
                #
                # Improving the crawler by tweaking the way it analyzes individual intra-net content
                # should not require hacking in code here - Need a way to squirt in per-site specific
                # analyzers...
                title_element = doc.at("head/title")
                if title_element # Test this change!
                    crawled_title_1 = title_element.inner_html
                    crawled_title_2 = crawled_title_1
                    crawled_title_2 = crawled_title_1.sub(params[:title_strip], '') if params[:title_strip]
                    crawled_title = crawled_title_2.strip if (crawled_title_1 != crawled_title_2)
                end
                # Ideas
                post_title_elements = nil
                unless post_title_elements
                    post_title_elements = doc.search("//div[@class='contentheading bh_suggestiontitle']")
                    if post_title_elements.length == 1
                        crawled_title = post_title_elements.text
                    end
                end
                # Blog
                unless post_title_elements
                    post_title_elements = doc.search("//div.post-title/h1/a")
                    if post_title_elements.length == 1
                        crawled_title = post_title_elements.text
                    end
                end
            rescue
                log.warn("Error extracting links for #{uri}")
            ensure
                content.rewind
            end
        end
        [crawled_title, links]
    end
end

# Crawler
#########

class Crawler

    def Crawler.crawl(params)
        to_process = { params[:url] => "" }
        crawled = Set.new
        depth = 0

        while !to_process.empty?
            links = {}
            to_process.each do |uri, referer|
                id = Crawler.unique_id(uri)
                if Crawler.valid_uri?(uri, params[:ignore])
                    begin
                        sleep(params[:wait]) if params[:wait]
                        # Consider adding explicit accept and language fields
                        # '*' Set these before using
                        uri.open(
                            "User-Agent" => params[:user_agent],
                            "From" => params[:from],
                            "Referer" => referer.to_s
                        ) do |content|
                            crawled_title, new_links = ContentAnalyzer.extract_links(uri, content, params)
                            links.merge!(new_links)
                            unless Crawler.is_path?(uri)
                                temp_file = Tempfile.new("content")
                                temp_file.binmode
                                begin
                                    temp_file << content.readlines
                                    temp_file.flush()
                                    temp_file.close()
                                    if params[:index]
                                        yield uri, content, temp_file.path, id, crawled_title, depth, params[:solr], params[:log] if block_given?
                                        params[:log].info("Indexed #{uri}")
                                    else
                                        params[:log].info("Would have indexed #{uri}")
                                    end
                                ensure
                                    temp_file.unlink()
                                end
                            else
                                params[:log].warn("Skipping indexing as path URL #{uri}") unless params[:quiet]
                            end
                        end
                    rescue OpenURI::HTTPError => e
                        params[:log].warn("Error opening #{uri} #{e}") unless params[:quiet]
                    end unless crawled.include?(id)
                else
                    params[:log].warn("Skipped #{uri}") unless params[:quiet]
                end
                crawled.add(id)
            end
            to_process = links
            break if (params[:depth] and depth >= params[:depth])
            depth += 1
        end
        crawled
    end

    def Crawler.valid_uri?(uri, ignore)
        return false if uri.scheme != 'http' or uri.fragment
        return false if ignore.any? {|reg| uri.to_s =~ /#{Regexp.quote(reg)}/}
        return true
    end

    # Crawl, don't index path uri's - Possibly this should be an option
    def Crawler.is_path?(uri)
        return uri.to_s =~ /\/$/
    end

    def Crawler.unique_id(uri)
        digest = Digest::MD5.new().update(uri.normalize().to_s)
        digest.hexdigest
    end
end

# SolrCrawler
#############

class SolrCrawler
    def SolrCrawler.crawl(options)
        Crawler.crawl(options) do |uri, content, file, id, crawled_title, depth, solr, log|
            if crawled_title
                solr_url = URI.join(solr.to_s, "update/extract?literal.id=#{id}&literal.crawled_title=#{CGI.escape(crawled_title)}&commit=true&literal.url=#{CGI.escape(uri.to_s)}")
            else
                solr_url = URI.join(solr.to_s, "update/extract?literal.id=#{id}&commit=true&literal.url=#{CGI.escape(uri.to_s)}")
            end
            solr_args = "\"#{solr_url}\" -H '#{CGI.escape("Content-type:" + content.content_type)}' -F \"myfile=@#{Pathname.new(file)}\""
            log.warn("#{uri} Curl failed") unless SolrCrawler.curl(solr_args)
        end
    end

    # This is here to simplify unit-testing, couldn't be bothered overriding back-tic's
    def SolrCrawler.curl(s)
        `curl #{s}`
        $?.success?
    end
end

# Options
#########

class CrawlerOptions
    def CrawlerOptions.get_options(args)
        options = {}
        options[:ignore] = []
        options[:logname] = nil
        options[:index] = false
        options[:user_agent] = "Crawler/1.0"
        options[:from] = "foo@bar.com"
        options[:wait] = 1
        
    
        opts = OptionParser.new do |opts|
            opts.banner = "(web) crawler for indexing content into Solr. To use a proxy, set http_proxy=http://foo:1234"
            opts.separator ""
            opts.on("-u URL", "--url URL", String, "Initial URL to crawl") {|u| options[:url] = URI.parse(URI.escape(u)) }
            opts.on("-s URL", "--solr URL", String, "URL to Solr") {|u| options[:solr] = URI.parse(URI.escape(u)) }
            opts.on("-t TEXT", "--title TEXT", String, "Strip TEXT from the title") {|u| options[:title_strip] = u }
            opts.on("-l NAME", "--log NAME", String, "NAME of log file (else STDOUT)") {|u| options[:logname] = u }
            opts.on("-a NAME", "--useragent NAME", String, "User agent name") {|u| options[:user_agent] = u }
            opts.on("-f FROM", "--from FROM", String, "From details") {|u| options[:from] = u }
            opts.on("-i x,y,z", "--ignore x,y,z", Array, "Ignore url's matching given patterns") {|list| options[:ignore] = list }
            opts.on("-w N", "--wait N", Integer, "Wait N seconds between each fetch") {|n| options[:wait] = n }
            opts.on("-d D", "--depth D", Integer, "Max depth to crawl") {|d| options[:depth] = d }
            opts.on("-e", "--index", "Crawl AND index the content") { |v| options[:index] = v }
            opts.on("-q", "--quiet", "Reduce log messages to informational only") { |q| options[:quiet] = q }
            opts.on("--yuk", "Horrible hack to fix poor CDATA termination, specific to a site - fix") {|y| options[:yuk] = y }
            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit(0)
            end
        end
    
        begin
            opts.parse!(args)
            unless options[:url] and options[:solr]
                puts "You must specify a root url (-u) and a url to Solr (-s)"
                exit(-1)
            end
        rescue OptionParser::InvalidOption => e
            puts e
            exit(-1)
        end
        
        if options[:solr].path =~ /\/$/
            options[:solr].path = options[:solr].path[0..-2]
        end
    
        options
    end
end

# Main
######
if __FILE__ == $0

    options = CrawlerOptions.get_options(ARGV)

    logger = if options[:logname]
        Logger.new(options[:logname], 'daily')
    else
        Logger.new(STDOUT)
    end
    logger.level = Logger::INFO
    options[:log] = logger

    logger.info("Root URL: #{options[:url]}")
    logger.info("Solr URL: #{options[:solr]}")
    logger.info("Ignoring: #{options[:ignore].join(',')}")
    logger.info("Waiting #{options[:wait]} seconds between a fetch")
    logger.info("Indexing #{options[:index]}")

    started = Time.now
    
    begin
        urls_crawled = SolrCrawler.crawl(options)
        logger.info("Crawled #{urls_crawled.length} url(s) in #{(Time.now - started)/60.0} minutes")
    rescue Exception => e
        puts "Unhandled exception: #{e}"
        logger.fatal("Unhandled exception: #{e}")
        exit(-1)
    end
end
