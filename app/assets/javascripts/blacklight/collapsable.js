// app/assets/javascripts/blacklight/collapsable.js
//
// This code has been modified from the original Blacklight source in order to
// allow click handler overrides for href="" as well as href="#".
//
// @see https://github.com/projectblacklight/blacklight/blob/v7.0.1/app/javascript/blacklight/collapsable.js

(function($) {
    Blacklight.onLoad(function() {

        var COLLAPSIBLE_LINKS = [
            'a[data-toggle=collapse][href="#"]',
            'a[data-toggle=collapse][href=""]',
            '[data-toggle=collapse] a[href="#"]',
            '[data-toggle=collapse] a[href=""]'
        ].join(', ');

        // When clicking on a link that toggles the collapsing behavior, don't
        // do anything with the hash or the page could jump around.
        $(document).on('click',
            COLLAPSIBLE_LINKS,
            function(event) { event.preventDefault(); }
        );

    });
})(jQuery);
