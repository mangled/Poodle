#!/usr/bin/env ruby
require 'rubygems'
require 'uri'
require 'optparse'
require 'rexml/document'
require 'rexml/formatters/default'

module Poodle
    class CrawlerOptions

        def CrawlerOptions.default
            options = {}
            options[:ignore] = []
            options[:accept] = []
            options[:logname] = nil
            options[:index] = false
            options[:user_agent] = "Crawler/1.0"
            options[:from] = "foo@bar.com"
            options[:threads] = 1
            options[:wait] = 1
            options[:cache_enabled] = false
            options[:index_dirs] = false
            options
        end

        def CrawlerOptions.get_options(args)
            options = CrawlerOptions.default

            opts = OptionParser.new do |opts|
                opts.banner = "(web) crawler for indexing content into Solr. To use a proxy, set http_proxy=http://foo:1234"
                opts.separator ""
                opts.on("-u URL", "--url URL", String, "Initial URL to crawl") {|u| options[:url] = URI.parse(URI.escape(u)) }
                opts.on("-s URL", "--solr URL", String, "URL to Solr") {|u| options[:solr] = URI.parse(URI.escape(u)) }
                opts.on("-t TEXT", "--title TEXT", String, "Strip TEXT from the title") {|u| options[:title_strip] = u }
                opts.on("-l NAME", "--log NAME", String, "NAME of log file (else STDOUT)") {|u| options[:logname] = u }
                opts.on("-a NAME", "--useragent NAME", String, "User agent name") {|u| options[:user_agent] = u }
                opts.on("-f FROM", "--from FROM", String, "From details") {|u| options[:from] = u }
                opts.on("-i x,y,z", "--ignore x,y,z", Array, "Ignore url's matching given patterns (not a regexp)") {|list| options[:ignore] = list }
                opts.on("-c x,y,z", "--accept x,y,z", Array, "Only process url's matching given patterns (not a regexp)") {|list| options[:accept] = list }
                opts.on("-w N", "--wait N", Integer, "Wait N seconds between each fetch") {|n| options[:wait] = n }
                opts.on("-e", "--index", "Crawl AND index the content") { |v| options[:index] = v }
                opts.on("-q", "--quiet", "Reduce log messages to informational only") { |q| options[:quiet] = q }
                opts.on("--index-dirs", "Index content of directory uri's e.g. http://foo/bar/ to be indexed") { |d| options[:index_dirs] = d }
                opts.on("--scope-to-root", "Only index if uri matches, completely, the initial root url path") { |s| options[:scope_uri] = true }
                opts.on("--local-cache", "Enable local caching of data (off by default)") {|l| options[:cache_enabled] = l }
                opts.on("-h N", "--threads N", Integer, "Set number of crawler threads to use") {|t| options[:threads] = t}
                opts.on("--yuk", "Horrible hack to fix poor CDATA termination, specific to a site - fix") {|y| options[:yuk] = y }
                opts.on_tail("-h", "--help", "Show this message") do
                  puts opts
                  exit(0)
                end
            end
        
            begin
                opts.parse!(args)
                unless options[:url] and options[:solr]
                    raise RuntimeError, "You must specify a root url (-u) and a url to Solr (-s)"
                end
                if !options[:ignore].empty? and !options[:accept].empty?
                    raise RuntimeError, "Please specify either an accept or an ignore list"
                end
            end
    
            options
        end
    end
end
