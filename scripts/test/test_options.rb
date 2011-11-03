#!/usr/bin/env ruby

require 'rubygems'
require 'test/unit'
require 'mocha'
require 'uri'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'options'

module Poodle
  class TestOptions < Test::Unit::TestCase
  
    def setup
      @root = "http://www.crawl.com/"
      @solr = "http://www.solr.com/"
      @opts = ["-u", @root, "-s", @solr]
    end
  
    def test_no_arguments
      exception = assert_raise(RuntimeError) { CrawlerOptions.get_options([]) }
      assert_match "You must specify a root url (-u) and a url to Solr (-s)", exception.message
    end
  
    def test_missing_argument
      exception = assert_raise(OptionParser::MissingArgument) { CrawlerOptions.get_options(["-u"]) }
      assert_match "missing argument: -u", exception.message
    end
  
    def test_invalid_option
      exception = assert_raise(OptionParser::InvalidOption) { CrawlerOptions.get_options(["--space_man"]) }
      assert_match "invalid option: --space_man", exception.message
    end
    
    def test_either_accept_or_ignore
      excecption = assert_raise(RuntimeError) { CrawlerOptions.get_options(@opts + ["-i", "1,2", "-c", "4,5"]) }
      assert_match "Please specify either an accept or an ignore list", excecption.message
    end

    def test_optional_options
      do_test_opt("-t", "--title", "1", :title_strip)
      do_test_opt("-l", "--log", "2", :logname)
      do_test_opt("-a", "--useragent", "3", :user_agent)
      do_test_opt("-f", "--from", "4", :from)
      do_test_opt("-i", "--ignore", "1,2,3", :ignore, ["1","2","3"])
      do_test_opt("-c", "--accept", "1,2,3", :accept, ["1","2","3"])
      do_test_opt("-w", "--wait", "5", :wait, 5)
      do_test_opt("-e", "--index", true, :index)
      do_test_opt("-q", "--quiet", true, :quiet)
      do_test_opt("-h", "--threads", "3", :threads, 3)
      do_test_opt(nil, "--index-dirs", true, :index_dirs)
      do_test_opt("--yuk", "--yuk", true, :yuk)
      do_test_opt(nil, "--local-cache", true, :cache_enabled)
      do_test_opt(nil, "--scope-to-root", true, :scope_uri)
    end
  
    def do_test_opt(short, long, value, option, converted_value = nil)
      if short
        options = CrawlerOptions.get_options(@opts + [short, value])
        assert_equal converted_value ? converted_value : value, options[option]
      end
      if long
        options = CrawlerOptions.get_options(@opts + [long, value])
        assert_equal converted_value ? converted_value : value, options[option]
      end
    end
    
    def test_defaults
      options = CrawlerOptions.get_options(@opts)
      assert_equal @root, options.delete(:url).to_s
      assert_equal @solr, options.delete(:solr).to_s
      assert_equal [], options.delete(:ignore)
      assert_equal [], options.delete(:accept)
      assert_nil options.delete(:logname)
      assert_equal false, options.delete(:index)
      assert_equal "Crawler/1.0", options.delete(:user_agent)
      assert_equal "foo@bar.com", options.delete(:from)
      assert_equal 1, options.delete(:wait)
      assert_equal 1, options.delete(:threads)
      assert_equal false, options.delete(:cache_enabled)
      assert_equal false, options.delete(:index_dirs)
      assert_equal 0, options.length
    end
  end
end
