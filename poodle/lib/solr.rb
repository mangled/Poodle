#!/usr/bin/env ruby
#
# Unit tests are in poodle/test/unit/solr_test
require 'rsolr'
require 'text_utilities'

class Solr

    # If present crawled title becomes the defacto title else
    # we use the Solr title, if this isn't present we use the first
    # keyword, else the url
    def Solr.format_keywords(url, keywords, titles, crawled_title)
        title = nil
        title = crawled_title.strip if crawled_title and not crawled_title.empty?
        title = titles[0].strip if title.nil? and titles and not titles.empty?

        words = keywords ? keywords.split(",") : []
        if title.nil? or title.empty? or title =~ /<.+>/
            title = url.split("/")[-1]
            title = words[0] if words.length > 0
        end
        words = words.reject{|ws| ws.strip == title.strip }
        [title, words[0..4]]
    end

    def Solr.format_highlighted_words(words)
        words.gsub(/\s{2,}/, " ").strip
    end

    def Solr.find(term, solr, start_index, max_hits)
        begin
            rsolr = RSolr.connect :url => solr

            response = rsolr.select(
                {:q => term, :start=>start_index, :rows=>max_hits, :wt => :ruby, :hl=>"on", "hl.fl" =>"search", :fl =>"id,url,keywords,title,crawled_title"}
            )

            highlighted_words = Hash.new("")
            response["highlighting"].each do |id, info|
                if info["search"] and not info["search"].empty?
                    highlighted_words[id] = Solr.format_highlighted_words(info["search"][0])
                end
            end

            results = []
            response["response"]["docs"].each do |doc|
                title, keywords = Solr.format_keywords(doc["url"], doc["keywords"], doc["title"], doc["crawled_title"])
                results << {
                    :url => doc["url"],
                    :keywords => keywords,
                    :title => title,
                    :text => TextUtilities.wrap(highlighted_words[doc["id"]], 80)
                }
            end

            results
        rescue Errno::ECONNREFUSED
            raise "Connection to Solr refused"
        rescue Errno::ETIMEDOUT
            raise "Connection to Solr timed out"
        end
    end
end
