Release: 1.0
============

This is the current "to-do" list for release 1.0. If you wish to contribute, then tackling any of these items would be a great help. Hopefully they are clear enough to get going, else e-mail <a href="http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=">me</a>.

01. Update the crawler to index files/folders (*really* - just crawl web front ends to file systems? Nice to have for now?)
02. Add a check in the crawler for url length > 1024 - Basically improve cycle checking
04. RSS feeds/news via AJAX on the right of the poodle search page. Suggest using http://railscasts.com/episodes/128-starling-and-workling in the background to parse the title's and url's from feeds and put in the database. When a user visits the page the last "x" titles are displayed.
05. Want to index, outlook newsgroups (folders), Trac...
06. Move Solr to non-example folder etc.
08. Add a new field to categorise content crawler -f "wiki" or -f "blog", this allows material specific queries
09. Add image search. Suspect you can do this from the content type field?
10. Save search terms and provide a hint when user types in search box
11. Investigate using rsolr instead of curl
12. Improve blog crawling, basically pages which are more like recent news are a pain as they aren't typically what a user wants to search for
13. Solr library should/could be a model - More rails like?
14. The title text for pdf's/ppt is generally rubbish!
15. Make it more rails 3 (some parts are older style due to my experience)
16. Returned highlight remove any leading/trailing ".\":()" etc. (don't knacker emphasis though)
17. Offer links from solr results? Solr provides links for the content, possibly add a "+" option to get at them?
18. Unit test terms such as "R&D"
20. Extend solr tests for text formatting - I have added empty title and <> checks and limit keywords to three.
21. Add tests for open-search
22. Improve word wrap function, needs to remove space on newlines and the tests are pants :-)
23. Solr helper should have options for word-wrap passed in
24. No docs for code! So add some!!!
