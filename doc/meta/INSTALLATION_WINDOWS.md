[Poodle](index.html) Windows Installation
=========================================

I have tested these instructions on a number of systems, hopefully you will sail through them. If you have problems with firewalls then I suggest you look at [NTLMAPS](http://sourceforge.net/projects/ntlmaps/) as a possible solution, or [rubysspi](http://rubyforge.org/projects/rubysspi/).

Note I'm using a completely clean install - I'm not providing instructions that cover upgrading any pre-installed components. If you are in this situation please review the information and tread carefully, for example upgrading ruby might cause other programs problems.

[Install Ruby](http://www.ruby-lang.org/en/)
--------------

Note: You need ruby `1.8.7` or higher as the web-app uses rails 3.0

I used the windows installer: [Ruby 1.8.7-p302 RubyInstaller](http://rubyforge.org/frs/download.php/72085/rubyinstaller-1.8.7-p302.exe) or http://rubyinstaller.org/downloads/

Added ruby exec's to PATH and associated .rb with this install, once complete the command line should indicate something along these lines:

        Z:\>ruby -v
        ruby 1.8.7 (2010-08-16 patchlevel 302) [i386-mingw32]

[Ruby Development Kit](http://github.com/oneclick/rubyinstaller/wiki/development-kit)
---------------------

To compile some gems (e.g. hpricot) you will need this installed (or change gem includes which complain - by modifying related GemFile's). I went for the dev. kit approach.

Download the latest [dev. kit.](http://rubyinstaller.org/downloads/), I went for the most [recent](http://github.com/downloads/oneclick/rubyinstaller/DevKit-4.5.0-20100819-1536-sfx.exe) at the time.

The installation instructions are on the site and are easy to follow. Download, extract e.g. 'C:\DevKit', cd into it and execute the instructed commands.

[Curl](http://curl.haxx.se/download.html)
------

At the moment the indexing scripts use Curl to push data to Solr, windows doesn't ship with curl, so you will need to install it. 

At the time I used `curl-7.21.1-ssl-sspi-zlib-static-bin-w32.zip`, I reached it using the download wizard, selecting executable, win32/xp.

Extract the .zip e.g. to `C:\curl`, you will get, `C:\curl\curl-7.21.1-ssl-sspi-zlib-static-bin-w32`, then add this path to your PATH.

Open a new cmd line and check it's installed:

        Z:\>curl -V
        curl 7.21.1 (i386-pc-win32) libcurl/7.21.1 OpenSSL/0.9.8o zlib/1.2.5
        Protocols: dict file ftp ftps http https imap imaps ldap pop3 pop3s rtsp smtp sm
        tps telnet tftp
        Features: AsynchDNS Largefile NTLM SSL SSPI libz

[SQlite3](http://www.sqlite.org/)
--------

The web-application is built using ruby-on-rails, for now I have stuck with the default choice of database, sqlite. You will need this installed.

Go to the site and grab the latest precompiled binaries for windows, at the time this was: `http://www.sqlite.org/sqlitedll-3_7_3.zip`, you only need the .dll (it does depend on MSVCRT.DLL if this isn't installed on your system then you can get it from Microsoft (as a redistributable).

Download, unzip, e.g. to `C:\sqlitedll-3_7_3`. Add this path to your PATH.

Java JDK
--------

Java (1.5 or greater) is required for [Solr](http://lucene.apache.org/solr/), I used the latest [JDK](http://www.oracle.com/technetwork/java/javase/downloads/index.html) from Oracle.

Almost done!
============

With the above installed you need to pull in the required gems and fetch/configure Apache Solr, return to [Common/Remaining Set-up](file.INSTALLATION.html#Set-up_Environment) and please follow the instructions.
