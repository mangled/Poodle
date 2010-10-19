[Poodle](../index.html) Example Site
=================================

To help you test out crawling and searching I have captured a snapshot of my [blog](http://mangled.me/blog/).

*Unzip* the content of `./Poodle/test-site/mangled.me.zip`, to the *same* folder (`./Poodle/test-site/`), i.e. you should have a `mangled.me` folder alongside the .zip folder and then run `server.rb`, you should see something like this:

        >ruby server.rb
        [2010-10-13 17:03:24] INFO  WEBrick 1.3.1
        [2010-10-13 17:03:24] INFO  ruby 1.8.7 (2010-08-16) [i386-mingw32]
        [2010-10-13 17:03:24] INFO  WEBrick::HTTPServer#start: pid=4752 port=8080

This will provide you with a "test-site" to try out crawling etc. with. E.g. point a browser at `http://localhost:8080/`, you should be able to browse around the blog content.

Now go and try [crawling](../scripts/index.html) the content.

