/*jslint white: false, onevar: true, undef: true, nomen: true, eqeqeq: true, plusplus: true, bitwise: true, regexp: false, strict: true, newcap: true, immed: true */
/*global $, jQuery, window */
"use strict";

$(document).ready(function() {
    $('input.query').defaultify();

    $('#quicksearch').submit(function(){alert("You clicked the search button");return false;});
});
