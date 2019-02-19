// app/assets/javascripts/blacklight/collapsable.js
//
// This code is essentially unchanged from the original Blacklight source.
// @see https://github.com/projectblacklight/blacklight/blob/v7.0.1/app/javascript/blacklight/collapsable.js

(function($) {
    Blacklight.onLoad(function() {
        // When clicking on a link that toggles the collapsing behavior, don't
        // do anything with the hash or the page could jump around.
        $(document).on('click',
            'a[data-toggle=collapse][href="#"], [data-toggle=collapse] a[href="#"]',
            function(event) { event.preventDefault(); }
        );
    });
})(jQuery);
