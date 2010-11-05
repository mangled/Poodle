[Poodle](../index.html) Crawling/Indexing
======================================

The crawler is a separate script in `./Poodle/script/lib`.

Again the code is an example, I have used it on an intra-net but I would not trust it to crawl the web - If you do then I take no responsibility :-)

The script is in ruby and it has built in "help". I.e. at a command prompt (in the `./Poodle/script/lib` folder) type `crawler.rb -h` or `ruby crawler.rb -h` you should see something along the lines of:

        (web) crawler for indexing content into Solr. To use a proxy, set http_proxy=http://foo:1234

            -u, --url URL                    Initial URL to crawl
            -s, --solr URL                   URL to Solr
            -t, --title TEXT                 Strip TEXT from the title
            -l, --log NAME                   NAME of log file (else STDOUT)
            -a, --useragent NAME             User agent name
            -f, --from FROM                  From details
            -i, --ignore x,y,z               Ignore url's matching given patterns (not a regexp)
            -c, --accept x,y,z               Only process url's matching given patterns (not a regexp)
            -w, --wait N                     Wait N seconds between each fetch
            -e, --index                      Crawl AND index the content
            -q, --quiet                      Reduce log messages to informational only
            -h, --threads N                  Set number of crawler threads to use
            --yuk                            Horrible hack to fix poor CDATA termination, specific to a site - fix
            --help                           Show this message

Perform a test crawl
--------------------

Start up Solr (it should be configured, if not see [installation](file.INSTALLATION.html)) by going into the solr example directory e.g. `/apache-solr-1.4.1/example/` and typing: `java -jar start.jar`

Now run up the crawler against some content - I have provided a ".zip" of my blog and a small server to permit content to be accessed. For more information on setting this up, go [here](../test-site/index.html)

An example command line is as follows (as used to index a media-wiki site):

        ruby crawler.rb -h 3 -l log.txt -t '- Wiki' -e -a "Search-Crawler/1.0" -f "foo@bar.com" -u "http://wiki/index.php?title=Main_Page" -s "http://localhost:8983/solr/" -i Special:,action=edit,printable=,oldid=,action=history,diff=,.exe,.asp,.dot

To crawl the example "test-site", you could use the following:

	ruby crawler.rb -h 3 -l mangled.log -e -a "Search-Crawler/1.0" -f "foo@bar.com" -u "http://localhost:8080/blog/index.html" -s "http://localhost:8983/solr/" -i category,tag

You *need* to look at the logs and experiment with indexing as its highly likely you will need to fine tune rejection of URL's. Some site content especially blogs have a large amount of redundant links.

Repeated calls re-index content (updating existing and adding new, deleting old content isn't handled by the crawler, see "Refresh Crawled Content" below).

Once you have crawled some content you can use the Solr "GUI" to query, again I advise looking at the Solr documentation, if you have followed the default installation instructions the service should be at [http://localhost:8983/solr/admin/](http://localhost:8983/solr/admin/). If you crawled my sample blog you should be aware that the crawler needs tweaking to handle blog type content better (i.e. where a site has pages which link to many others), some terms to search for are 'lean' and 'ladder'. You should find better results using internal content.

You should run a cron job or Windows scheduled action to fire off indexing, say once a day.

Refresh Crawled Content
-----------------------

I have also written a script which checks the integrity of the Solr content, by checking stored URL's and deleting indexed items whose URL is "bad". This script should be run regularly, but less often than the indexers.

The script is called `purge.rb` and can be found in `./Poodle/script/lib`. Again it has built in help, if you type (in the `./Poodle/script/lib` folder) `purge.rb -h` or `ruby purge.rb -h` you should see something along the lines of:

        Purge tool for cleaning out invalid content from Solr - Paired with crawler. To use a proxy, set http_proxy=http://foo:1234
    
        -s, --solr URL                   URL to Solr
        -l, --log NAME                   NAME of log file (else STDOUT)
        -a, --useragent NAME             User agent name
        -f, --from FROM                  From details
        -w, --wait N                     Wait N seconds between each fetch
        -d, --delete                     Check AND delete the content
        -h, --help                       Show this message

It should be self-explanatory, an example usage would be:

        ruby .\lib\purge.rb -l purgelog.txt -d -a "Purge/1.0" -f "foo@bar.com" -s "http://localhost:8983/solr"

Proxies/Windows NTLM etc.
-------------------------

If you have problems with IIS and windows, then look at [NTLMAPS](http://sourceforge.net/projects/ntlmaps/), i.e. point the crawler at a the ntlmaps proxy and let it rip, works fine for me.

I have also had success using [rubysspi](http://rubyforge.org/projects/rubysspi/). Both the crawler and purge tools check for this and if it's available will use it. When using a proxy you will need to set the environment variable `http_proxy`. E.g. `http_proxy=http://foo:1234`

Issues
------

The crawler is still very much WIP and I expect it to be cleaner by version 1.0. It's grown organically and to be honest needs tidying.

Major limitations are no support for `robots.txt`, it's loop detection is almost non-existent - So it could quite easily wander off forever! It also lacks support for authentication and could do with indicating the content types it accepts. Lastly, it re-crawls and indexes all content and uses curl to stream with - Not optimal. Extending the crawler to handle these omissions isn't hard, I just didn't need to (crawling an intranet lowers or removes the need to implement these features).

If you find this code of use, you could help me write some crawlers for different content, shared files/folders, MS outlook/exchange content, Trac, the list is quite long.

What Next?
----------

Now you have some content crawled/indexed, try running up the web front end to [search the content](../poodle/index.html)
