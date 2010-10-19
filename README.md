<img src="./poodle.jpg" alt="Poodle" width="96" height="96"/>

[Poodle](file.VERSION.html)
========

Poodle is collection of ruby based "tools" which work collectively with Apache Solr to produce a simple intranet search tool. It is similar to the Java based Nutch search tool - Although at present nowhere near as rounded.

The aim is to provide simple code which can be easily modified to your own needs. Its **not** an out of the box solution, although it should be fairly usable "as-is". The simplest modifications are cosmetic, if you want to go further then hack away - I produced this for my own needs and wished something like this had existed at the time. I do not pretend to be an expert on ruby/rails etc. I also assume that anyone looking at this has some experience of ruby/rails and general coding etc.

Help
----

This is a fairly early version, its functional enough to be useful and is being used in earnest ("in production") serving small organisations.

The code is public (on GitHub) so feel free to fix omissions etc. the current wish list of features/fixes are held in [./doc/meta/TODO.md](file.TODO.html). I expect to implement most of this wish list for version `1.0`

What now
--------

1. [Set up your environment](file.INSTALLATION.html)
2. [Index content](./scripts/index.html)
3. [Search content](./poodle/index.html)

If pre-compiled documentation is missing then open up `./doc/meta/INSTALLATION.md` in your favourite text editor. If you have ruby, yard and BlueCloth installed then type: `rake` to generate `./doc/rdoc` (note that the [installation instructions](file.INSTALLATION.html) cover getting the environment configured)

Upgrading
---------

If you are upgrading, please see the [change list](file.CHANGES.html)

Thank-you
---------

This project relies on a number of "libraries" apologies if I have left any out:

- [Apache Solr](http://lucene.apache.org/solr/)
- [Bluff](http://bluff.jcoglan.com/)
- [RSolr](http://github.com/mwmitchell/rsolr)
- [Hpricot](http://github.com/hpricot/hpricot)
- [Fakeweb](http://fakeweb.rubyforge.org/)
- [Mocha](http://mocha.rubyforge.org/)
- [Bundler](http://github.com/carlhuda/bundler)
- [Yard](http://yardoc.org/)

Contact
-------

If you have any queries/problems, would like to contribute etc. then please contact me:

Regards,

- <a href="http://www.google.com/recaptcha/mailhide/d?k=01vdgNNADQlgrqj5lMuKLpag==&c=dLzYSFd6PdPBc5paL9eJKJ62wOQODVZwCaNzqvMcxyI=">(Mangled) Matthew</a>
