[Poodle](index.html) Ubuntu Installation
========================================

This was tested on Ubuntu 10.10 - the Maverick Meerkat. Using a completely clean install - I'm not providing instructions that cover upgrading any pre-installed components. If you are in this situation please review the information and tread carefully, for example upgrading ruby might cause other programs problems.

I imagine other distributions would require similar instructions.

[Install Ruby](http://www.ruby-lang.org/en/)
--------------

Note: You need ruby `1.8.7` or higher as the web-app uses rails 3.0 - This (at the time of writing) was the version provided for Ubuntu via a standard apt-get.

		`> sudo apt-get install ruby`

		matthew@foo:~$ ruby -v
		ruby 1.8.7 (2010-06-23 patchlevel 299) [i686-linux]

You will also need to install ruby gems

		`> sudo apt-get install rubygems`

		matthew@foo:~$ gem list

		*** LOCAL GEMS ***

I also need to update the version of gems installed through ubuntu:

        `sudo gem install rubygems-update`

Then (and *note* this step will remove any existing gems, also I had to use the full path to the gems bin folder e.g. `sudo /var/lib/gems/1.8/bin/update_rubygems`)

        `sudo update_rubygems`

Finally, you might need to add gems to your path to get them to run.

Type: `gem environment` and look at the executable directory, the chances are it isn't on your path. You can (in the short term i.e. for the duration of your shell) type the following, `export PATH=$PATH:/var/lib/gems/1.8/bin` (for example), or place it into your `.bashrc` or `.profile` file.

Build Essentials
----------------

This might not be required, but I'm paranoid!

		`> sudo apt-get install build-essential`

This is required to build native gems (note it ties to the ruby (major) version):

		`sudo apt-get install ruby1.8-dev`

This is alsi required:

        `sudo apt-get install libopenssl-ruby1.8`

[Curl](http://curl.haxx.se/download.html)
------

This is currently required for the indexer.

		`> sudo apt-get install curl'

[SQlite3](http://www.sqlite.org/)
--------

This is currently the default database type used by the Poodle web-front end. You can use another database if you like, you will need to alter Poodle's database details though. This isn't hard, but I'm not describing it here.

		`> sudo apt-get install sqlite3 libsqlite3-dev`

Java JDK
--------

Java (1.5 or greater) is required for [Solr](http://lucene.apache.org/solr/). I used the *ubuntu package manager* and download the default-jdk (which pointed to openjdk).

		matthew@foo:~$ java -version
		java version "1.6.0_20"
		OpenJDK Runtime Environment (IcedTea6 1.9) (6b20-1.9-0ubuntu1)
		OpenJDK Client VM (build 17.0-b16, mixed mode, sharing)

Almost done!
============

With the above installed you need to pull in the required gems and fetch/configure Apache Solr, return to [Common/Remaining Set-up](file.INSTALLATION.html#Set-up_Environment) and follow the instructions.

