#!/usr/bin/env ruby
# Ruby program to purge dead documents from Solr. This script should be run in
# tandem to the crawler. I.e. sometime after a crawl - This will ensure the
# solr database is fairly up-to-date.

require 'rubygems'
require 'rsolr'
require 'net/http'
require 'logger'
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
require 'optparse'

class SolrPurge
    
    def SolrPurge.purge(params)
        start_index, end_index, rows, results = SolrPurge.query(params[:solr], 0)
        items = SolrPurge.find_invalid_urls(results, params)
        while start_index + rows < end_index
            start_index, end_index, rows, results = SolrPurge.query(params[:solr], start_index + rows)
            items += SolrPurge.find_invalid_urls(results, params)
        end
        SolrPurge.delete_from_solr(params[:solr], items, params) if params[:delete]
    end

    def SolrPurge.query(solr, start)
        response = solr.select({:q => 'id:*', :start=> start, :rows=>10, :wt => :ruby, :fl =>'id,url'})
    
        start_index = response["response"]["start"].to_i
        end_index = response["response"]["numFound"].to_i
        rows = response["responseHeader"]["params"]["rows"].to_i
    
        results = {}
        response["response"]["docs"].each do |doc|
            results[doc["id"]] = doc["url"]
        end

        [start_index, end_index, rows, results]
    end
    
    def SolrPurge.find_invalid_urls(items, params)
        invalid_urls = []
        items.each do |id, url|
            begin
                sleep(params[:wait])
                if params[:remove] and url =~ /#{Regexp.quote(params[:remove])}/i
                    params[:log].info("Automatically removing #{url}")
                    invalid_urls << [id, url]
                else
                    uri = URI.parse(url)
                    params[:log].info("Checking #{uri}")
                    Net::HTTP.start(uri.host, uri.port) do |http|
                        request = Net::HTTP::Head.new(uri.request_uri)
                        request.body = ""
                        request.initialize_http_header({ "User-Agent" => params[:user_agent], "From" => params[:from], "Referer" => "" })
                        http.request(request).value # value triggers http exception unless 2xx
                    end
                end
            rescue URI::InvalidURIError => e
                params[:log].info("URI error for #{id} #{url} #{e}")
                invalid_urls << [id, url]
            rescue Net::HTTPRetriableError => e
                params[:log].info("HTTP error for #{id} #{url} #{e}")
                params[:log].info("Marking for deletion as crawler will re-index the redirect")
                invalid_urls << [id, url]
            rescue Net::HTTPServerException => e
                params[:log].info("HTTP error for #{id} #{url} #{e}")
                case e.message
                when '401 "Unauthorized"'
                    params[:log].info("Not marking for deletion as unauthorized")
                else
                    invalid_urls << [id, url]
                end
            rescue Net::HTTPFatalError => e
                params[:log].info("HTTP FATAL error for #{id} #{url} #{e}")
                invalid_urls << [id, url]
            end
        end
        invalid_urls
    end

    def SolrPurge.delete_from_solr(solr, items, params)
        unless items.empty?
            params[:log].info("Removing #{items.length} from Solr")
            items.each do |item|
                params[:log].info("Preparing to delete #{item[1]}")
                solr.delete_by_id item[0]
            end
            params[:log].info("Committing deletion request(s)")    
            solr.commit
        end
    end
    
end

def delete(url, items)
    solr = RSolr.connect(:url => url)
    puts "Removing #{items.length}"
    items.each do |item|
        puts "Deleting #{item[1]}"
        solr.delete_by_id item[0]
    end
    solr.commit
end

def find_dead_content(url, ids)
    delete = []
    ids.each do |id, url|
        begin
            sleep(0.025)
            open(url, "User-Agent" => "foo", "From" => "bar", "Referer" => "") # ONLY want headers, switch to Net::Http?
        rescue URI::InvalidURIError => e
            puts "#{id} #{url} #{e}"
            delete << [id, url]
        rescue OpenURI::HTTPError => e
            puts "#{id} #{url} #{e}"
            if e.io.status[0].to_i != 401
                puts "#{e.io.status[0].to_i}"
                delete << [id, url]
            end
        end
    end
    delete
end

def query_content(url, start = 0)
    solr = RSolr.connect(:url => url)

    response = solr.select({:q => 'id:*', :start=> start, :rows=>10, :wt => :ruby, :fl =>'id,url'})

    start_index = response["response"]["start"].to_i
    end_index = start_index + response["response"]["numFound"].to_i
    rows = response["responseHeader"]["params"]["rows"].to_i

    results = {}
    response["response"]["docs"].each do |doc|
        results[doc["id"]] = doc["url"]
    end

    [start_index, end_index, rows, results]
end

# Options
#########

class PurgeOptions
    def PurgeOptions.get_options(args)
        options = {}
        options[:logname] = nil
        options[:delete] = false
        options[:user_agent] = "Purge/1.0"
        options[:from] = "foo@bar.com"
        options[:wait] = 0.25
        options[:remove] = nil
    
        opts = OptionParser.new do |opts|
            opts.banner = "Purge tool for cleaning out invalid content from Solr - Paired with crawler. To use a proxy, set http_proxy=http://foo:1234"
            opts.separator ""
            opts.on("-s URL", "--solr URL", String, "URL to Solr") {|u| options[:solr_uri] = URI.parse(URI.escape(u)) }
            opts.on("-l NAME", "--log NAME", String, "NAME of log file (else STDOUT)") {|u| options[:logname] = u }
            opts.on("-a NAME", "--useragent NAME", String, "User agent name") {|u| options[:user_agent] = u }
            opts.on("-f FROM", "--from FROM", String, "From details") {|u| options[:from] = u }
            opts.on("-w N", "--wait N", Integer, "Wait N seconds between each fetch (defaults to #{options[:wait]} seconds") {|n| options[:wait] = n }
            opts.on("-d", "--delete", "Check AND delete the content") { |v| options[:delete] = v }
            opts.on("-r URL", "--remove URL", String, "Automatically remove any url's that match the given pattern (not a regexp)") {|s| options[:remove] = s }
            opts.on_tail("-h", "--help", "Show this message") do
              puts opts
              exit(0)
            end
        end
    
        begin
            opts.parse!(args)
            unless options[:solr_uri]
                puts "You must specify a url to Solr (-s)"
                exit(-1)
            end
        rescue OptionParser::InvalidOption => e
            puts e
            exit(-1)
        end
        
        if options[:solr_uri].path =~ /\/$/
            options[:solr_uri].path = options[:solr_uri].path[0..-2]
        end
    
        options
    end
end

# Main
######
if __FILE__ == $0

    options = PurgeOptions.get_options(ARGV)

    logger = if options[:logname]
        Logger.new(options[:logname], 'daily')
    else
        Logger.new(STDOUT)
    end
    logger.level = Logger::INFO
    options[:log] = logger
    
    options[:solr] = RSolr.connect(:url => options[:solr_uri].to_s)
    
    begin
        SolrPurge.purge(options)
    rescue Exception => e
        puts "Unhandled exception: #{e}"
        logger.fatal("Unhandled exception: #{e}")
        exit(-1)
    end
end
