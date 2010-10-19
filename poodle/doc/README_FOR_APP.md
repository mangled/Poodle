[Poodle](../index.html) Web-front end
======================================

I'm assuming you have followed all the recommended [installation](../file.INSTALLATION.html) instructions and are now in the final phase of running up a front end to Solr.

The front end for Poodle is a simple ruby on rails application, located at `./Poodle/poodle/`

Configuring
-----------

A number of settings can be altered through the file: `./Poodle/poodle/config/application.yml`

Example contents:

        defaults: &defaults
            revision: 0.9
            title: Poodle
            feedback_email: foo@bar.com
            description: A web based search engine
            icon: favicon.ico
            search_results_per_page: 10
            solr_url: http://localhost:8983/solr
            solr_fail: Failed to complete query, please contact technical support
            browser_fail: You must have JavaScript enabled. Please enable it and return to the search page.
            stats_hits_per_day_title: Last seven days
            stats_hits_per_day_no_data: No click-through's in the last seven days!
            stats_hits_per_day_search_count_text: Number of searches
            stats_hits_per_day_clicked_count_text: Number of clicked search results
        
            ...

Hopefully the items are obvious. Probably the only items of interest are the "title", "feedback email" and "solr url" parameters. You can set them at any time.

Running
-------

Change into the directory `./Poodle/poodle/` and type `rails server`, once its running point your browser at [http://localhost:3000/](http://localhost:3000/)

You should see the Poodle search box, type some terms in!!!

What Now?
---------

This release of Poodle is rounded enough to provide a starting point for expansion, the crawler really needs tidying and improving and the web-front end could be improved in many ways. I have plans to tackle some of these items for version 1.0.

The current wish list is [here](../file.TODO.html)

Hopefully you will find the code simple enough to tune to your needs, so please go play! Any code contributions welcome also :-)

Regards,

- <a href="http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=">(Mangled) Matthew</a>

