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
require 'net/http'

module Poodle
    class AnalyzerError < RuntimeError; end

    class Analyzer

        def extract_links(uri, referer, params)
            begin
                content = uri.open("User-Agent" => params[:user_agent], "From" => params[:from], "Referer" => referer.to_s)
                crawled_title, new_links = analyze(uri, content, params)
                [crawled_title, new_links, content]
            rescue OpenURI::HTTPError => e
                params[:log].warn("Error opening #{uri} #{e}")
                raise AnalyzerError, e
            end
        end

        def analyze(uri, content, params)
            log = params[:log]
            crawled_title = nil
            links = []
    
            if content.content_type == 'text/html'
                begin
                    # !!! Arg. one of the sites I'm indexing has badly terminated CDATA, this is horrid!!!
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
                            if link.scheme == 'http'
                                if uri.host == link.host # Stay in same site: By design, relax/remove this at your own risk
                                    links << [link, uri] unless links.include? link
                                else
                                    log.warn("Skipping as host differs #{link}") unless params[:quiet]
                                end
                            else
                                log.warn("Skipping as non-http #{link}") unless params[:quiet]
                            end
                        rescue URI::InvalidURIError => e
                            log.warn("Invalid link in page #{uri} : #{e}")
                        end
                    end
                    crawled_title = find_title(doc, params[:title_strip])
                rescue
                    log.warn("Error extracting links for #{uri}")
                ensure
                    content.rewind
                end
            end
            [crawled_title, links]
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
        def find_title(doc, title_strip)
            crawled_title = nil
            title_element = doc.at("head/title")
            if title_element
               crawled_title = title_element.inner_html.sub(title_strip, '').strip if title_strip
               crawled_title = nil unless crawled_title != title_element.inner_html
            end
            unless crawled_title # Ideas
               post_title_elements = doc.search("//div[@class='contentheading bh_suggestiontitle']")
               crawled_title = post_title_elements.text if post_title_elements.length == 1
            end
            unless crawled_title # (Wordpress) Blog
               post_title_elements = doc.search("//div.post-title/h1/a")
               crawled_title = post_title_elements.text if post_title_elements.length == 1
            end
            crawled_title
        end
    end
end