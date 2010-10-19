xml.instruct!
xml.OpenSearchDescription "xmlns" => "http://a9.com/-/spec/opensearch/1.1/", "xmlns:moz" => "http://www.mozilla.org/2006/browser/search/",
"xmlns:ie" => "http://schemas.microsoft.com/Search/2008/" do
xml.ShortName @title
xml.Description @description
xml.InputEncoding "UTF-8"
xml.Image @icon_path, :height => "16", :width => "16", :type => "image/x-icon"
xml.Url :type => "text/html", :method => "get", :template => "#{@host}/?search_term={searchTerms}"
end
