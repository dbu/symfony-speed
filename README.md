Symfony Frontend Performance Optimiziation Demo
===============================================

This demo contains a couple of branches that demonstrate the steps from a
non-optimized to a performance optimized site.

I aimed to provide a demo with as little other bundles and concepts as possible so you can
focus on the performance relevant things. Also I artificially bloat the
javascript and css files and added an usleep call to the controller to make the effects of caching
more visible. Just imagine this would be some real application that has the
latency and huge css and javascript files for a good reason :-)

# Play with this demo

Symfony and Apache both do an impressively good job at coping with slow code
and big files. Running webserver and browser on the same maschine also gives
unrealistic latencies. To get the full pain, I did:

* Disable symfony caching by adding ``cache: false`` to the twig section in config.yml
* Disable gzip compression in Apache by adding ``SetEnv no-gzip`` to the vhost entry
* Disable KeepAlive in apache.conf to make the problem of lots of single files more visible
* Use netem or [sloppy](http://www.dallaway.com/sloppy/) to simulate a low bandwith

Of course, using and optimizing these features instead of disabling them can be
a cheap way to speed up your website. You should look into this topic as well.
But there are limits, if for example the internet connection is really slow,
there are lots of big files that can not be compressed below a certain size.

To play with one of the branches, do not forget to first clear the cache with

    app/console cache:clear --env=prod --no-debug

If you don't, you will not get the expected results.


# How to use this repository

The master branch is the optimum solution. Each step is shown in its branch.
Go to the branch that interests use and do a git diff to the previous branch to
see what was changed.

See the wiki for a [list of branches](https://github.com/dbu/symfony-speed/wiki)
and information about them.


1) Download
-----------

## Clone the git Repository

Run the following commands:

    git clone http://github.com/dbu/symfony-speed.git
    cd symfony-speed


2) Installation
---------------

Thanks to composer this is pretty easy.

### a) Install the Vendor Libraries

Download composer following the instructions on http://getcomposer.org/ and
then run the following:

    php composer.phar install
    app/console assets:install --symlink web/


### b) Check your System Configuration

Now make sure that your local system is properly configured
for Symfony. To do this, execute the following:

    php app/check.php

If you get any warnings or recommendations, fix these now before moving on.


### c) Make sure comments can be written

To have comments stored, the webserver must be allowed to write the file

    /tmp/comments

 If you can not do that, edit the FILE constant in the controller
``src/Dbu/CoreBundle/Controller/CommentsController.php``
(In a real project this would go into parameters.yml of course.)


### d) Access the Application via the Browser

Now this symfony application should be ready to use. If you installed it into
the webroot, go to:

    http://localhost/

To see the performance impact of things, do not use the app_dev.php entry point
but the production entry point.

### e) Make your webserver realistically slow

With netem, use something like this when running the site locally:

    sudo tc qdisc add dev lo root netem delay 300ms 30ms
    sudo tc qdisc change dev lo root netem loss 0.10%
