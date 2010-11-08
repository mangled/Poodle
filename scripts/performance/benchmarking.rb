#!/usr/bin/env ruby
# Looking at cache performance

require 'rubygems'
require 'uri'
require 'time'
require 'benchmark'
require 'sqlite3'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")
require 'cache'
require 'synchronization'

def random_string(length)
  o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten;
  (0..length).map{ o[rand(o.length)]  }.join;
end

def random_url(site)
  url = []
  1.upto(rand(4)) { url << random_string(3) }
  url << random_string(8) + ".html"
  site.merge(url.join("/"))
end

site = URI.parse("http://www.foo.com/")
file_based_cache = Poodle::Cache.from_path(site, Time.parse("2010-01-01"), ".", true)

queue = Poodle::WorkQueue.new()

puts "Generating test data"
loop_n = 10000
urls = []
loop_n.times { urls << random_url(site) }

puts "Benchmarking"
Benchmark.bm(15) do |x|
  x.report("flb cache add") do # Transactions make a big difference - Implies that workqueue needs to commit result at the end?
    file_based_cache.hack_get_db.transaction
    loop_n.times { |i| file_based_cache.add(urls[i], urls[i], "title", i) }
    file_based_cache.hack_get_db.commit
  end
  x.report("wrk queue add") { loop_n.times { |i| queue.add([urls[i], urls[i]]) } }
  x.report("wrk queue next") { loop_n.times { |i| queue.remove {|i|} } }
end
