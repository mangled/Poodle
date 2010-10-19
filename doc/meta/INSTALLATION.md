[Poodle](index.html) Installation
=================================

Installing and setting Poodle up is fairly simple, really it is, don't be put off by the number of steps - They are mainly watching installers go by. That said there is an assumption that you have some basic skills and understanding of package management/installers and the command line.

If asked I might provide a virtual machine image for an out of the box experience :-)

Overview
--------

Poodle consists of two major components:
- Indexing tools: Tools designed to crawl through content and feed it to Solr
- A web application: A simple ruby on rails based web front end to Solr

It is expected that a dedicated server will host Solr and the web-application, due to the nature of Solr this need not be the same machine i.e. Solr is a service which can be queried by many clients, one of which is the web-application.

Set-up Environment
------------------

Before using any of poodle you will need to get your development environment set-up/configured. I have tried to automate as much of this as possible and tested these instructions as best I can (on windows 32/64 bit and Ubuntu). I timed set-up from clean and I reckon its around 30-60 minutes.

- *Operating System Specific (do first)*

    - [Windows](file.INSTALLATION_WINDOWS.html)
    - [Ubuntu](file.INSTALLATION_UBUNTU.html)

- Remaining Set-up

    ####Install gems
    
    Windows:

        `> gem install rake`
        `> gem install bundler`

    Ubuntu:

        `> sudo gem install bundler`
        `> sudo gem install rake`
    
    Now "pull" in all the other required gems:
 
        `./Poodle>bundle install`
        `./Poodle>rake install:all`

    #### Create Database

        `../Poodle/poodle>rake db:migrate`

    Using the cmd line change into the directory "poodle", i.e. `./Poodle/poodle/` and type: `rake db:migrate` - This will set-up the web-app database. This should succeed!

    #### Run unit tests

    I have tried to add a reasonable level of unit tests (they could do with some re-factoring but they do have fairly good coverage). If *any* fail then *panic* and fix/ping-me.
    
    In the root folder (`./Poodle/`) type `rake test`. This will run *all* available tests, as said they should all pass.

    #### [Set-up Solr](http://lucene.apache.org/solr/)

    The Apache Solr documentation is good, so I advise using it, follow the [tutorial](http://lucene.apache.org/solr/tutorial.html), *up to the point where you are ready to run `java -jar start.jar` in the example application*.
    
    You need to ensure java is installed (instructions provided earlier), then download (.tgz or .zip - depending on your platform) and unzip Solr, e.g. to `C:\apache-solr-1.4.1` (for windows), or the home folder of the user who will be running the Solr service.
    
    I tested this with `Solr 1.4.1` (the latest version at the time of writing)

What Next?
----------

Once you have everything installed you are ready to configure Solr, index some content and search for it via the web "front-end". See the following documentation for more information.

1. [Configure Solr](./solr/index.html)
2. [Index content](./scripts/index.html)
3. [Search content](./poodle/index.html)

