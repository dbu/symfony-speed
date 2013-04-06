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

    # Lookup static files even with cookie and potential cache-busting query string
    if (req.url ~ ".*\.(css|js|png|gif|jpg|jpeg|swf|eot|woff|ttf)(\?.*)?$") {
        return (lookup);
    }

    # the default routine will only lookup if there is no cookie
}

# received data from backend
sub vcl_fetch {

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
}

sub vcl_pipe {
    set bereq.http.connection = "close";
}

