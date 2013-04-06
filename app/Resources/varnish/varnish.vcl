# Varnish Configuration
#
# A simple varnish configuration file with some checks, the purge handler and
# ttl custom header.
#
# The easiest way to develop is to symlink /etc/varnish/default.vcl
# to this file
#
# Unless you specify differently, varnish will listen for requests on port 6081
#
# See the vcl(7) man page for details on VCL syntax and semantics.
#
# Varnish can do much more than what is shown here. Read up on it
# and unleash its full power :-)
#

# Webserver backends

# local testing
backend default {
    .host = "127.0.0.1";
    .port = "80";
}

# who is allowed to purge from cache
# http://varnish-cache.org/trac/wiki/VCLExamplePurging
acl purge {
        "127.0.0.1"; #localhost for dev purposes
}

# incoming client request
sub vcl_recv {

    # tell backend we can handle ESI
    set req.http.Surrogate-Capability = "abc=ESI/1.0";

    if (req.request == "PURGE") {
        if (!client.ip ~ purge) {
            error 405 "Not allowed.";
        }
        purge("req.url ~ " req.url);
        log "PURGE " req.url;
        error 200 "Success";
    }

    if (req.restarts == 0) {
        if (req.http.x-forwarded-for) {
            set req.http.X-Forwarded-For = req.http.X-Forwarded-For ", " client.ip;
        } else {
            set req.http.X-Forwarded-For = client.ip;
        }
    }

    # request type handling taken from default vcl
    # Pass any requests that Varnish does not understand straight to the backend. Non-RFC2616 or CONNECT which is weird.
    if (req.request != "GET" && req.request != "HEAD" &&
        req.request != "PUT" && req.request != "POST" &&
        req.request != "TRACE" && req.request != "OPTIONS" &&
        req.request != "DELETE") {

        return(pipe);
    }
    # Pass anything other than GET and HEAD directly. We only deal with GET and HEAD
    if (req.request != "GET" && req.request != "HEAD") {
        return(pass);
    }
    if (req.http.Authorization) {
        return (pass);
    }

    # don't compress when using esi
    unset req.http.Accept-Encoding;

    # try to lookup even if there is a cookie
    return (lookup);
}

# received data from backend
sub vcl_fetch {

    if (beresp.http.Surrogate-Control ~ "ESI/1.0") {
        unset beresp.http.Surrogate-Control;
        # for varnish < 3.0:
        esi;
        # if you have varnish 3.0 or higher, enable this line instead:
        #set beresp.do_esi = true;
    }

    # set cache lifetime based on custom header
    # unfortunately beresp.ttl can only be set to constant values and not dynamically
    # so we have to use a fragment of C code here
    if (beresp.http.X-Reverse-Proxy-TTL) {
        C{
            char *ttl;
            ttl = VRT_GetHdr(sp, HDR_BERESP, "\024X-Reverse-Proxy-TTL:");
            VRT_l_beresp_ttl(sp, atoi(ttl));
        }C
        unset beresp.http.X-Reverse-Proxy-TTL;
    }

    # respect backend do not cache instruction
    if (beresp.http.Cache-Control ~ "(no-cache|no-store)") {
        return (pass);
    }

    # do not cache subrequests that vary (i.e. on cookie)
    if (beresp.http.Vary) {
        return (pass);
    }
}

sub vcl_deliver {
    if (! req.url ~ ".*\.(css|js|png|gif|jpg|jpeg|swf|eot|woff|ttf)(\?.*)?$") {
        # avoid caching by intermediary caches to mix up content of different users
        set resp.http.Vary = "Cookie";
        # if-modified-since will only confuse us, remove it
        unset resp.http.Last-Modified;
    }
}

sub vcl_pipe {
    set bereq.http.connection = "close";
}

