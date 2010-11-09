#!/usr/bin/env ruby
require 'rubygems'
require 'uri'

module Poodle
    module UrlUtilities
        def UrlUtilities.random_string(length)
          o =  [('a'..'z'),('A'..'Z')].map{|i| i.to_a}.flatten;
          (0..length).map{ o[rand(o.length)]  }.join;
        end
        
        def UrlUtilities.site_s(site)
            s = ["http://www"]
            if site.nil?
                s << random_string(4)
            else
                s << site.host
            end
            s << "com"
            s.join('.')
        end

        def UrlUtilities.random_url(site = nil)
          url = []
          url << UrlUtilities.site_s(site)
          1.upto(rand(4)) { url << random_string(3) }
          url << random_string(8) + ".html"
          URI.parse(url.join("/"))
        end
    end
end
