// app/assets/feature/gallery.js.erb
//
// Adds functionality to Blacklight::Gallery.

Blacklight.onLoad(function() {

    // Only perform these actions on the appropriate pages.
    var $gallery = $('#documents.gallery .thumbnail .caption');
    var $masonry = $('#documents.masonry .thumbnail .caption');
    if (isMissing($gallery) && isMissing($masonry)) { return; }

    /**
     * CSS class indicating that the details element should be made visible.
     *
     * @constant
     * @type {string}
     */
    var DETAILS_VISIBLE_MARKER = 'visible';

    // ========================================================================
    // Actions
    // ========================================================================

    // Make gallery view item metadata visible when the item is visited.
    $gallery.each(function() {
        var $caption = $(this);
        var $target  = $caption;
        showGalleryDetailsEvents($target, $caption);
    });

    // Make masonry view item metadata visible when the item is visited.
    $masonry.each(function() {
        var $caption = $(this);
        var $target  = $caption.parents('.thumbnail');
        showGalleryDetailsEvents($target, $caption);
    });

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Show/hide item information when visiting an item via mouse or keyboard.
     *
     * @param {Selector} target
     * @param {Selector} [caption]
     * @param {Selector} [popup]
     */
    function showGalleryDetailsEvents(target, caption, popup) {
        var $target  = $(target);
        var $caption = caption ? $(caption) : $target.find('.caption');
        var $popup   = popup   ? $(popup)   : $caption.find('.index-details');
        $target.hover(
            function() { showGalleryDetails($popup); },
            function() { hideGalleryDetails($popup); }
        );
        $caption.find('.index_title').find('a')
            .focus(function() { showGalleryDetails($popup); })
            .blur( function() { hideGalleryDetails($popup); });
    }

    /**
     * Show/hide item information target element.
     *
     * When the element is made visible, it acquires hover handlers so that it
     * stays visible if the user moves the mouse into it (or if scrolling into
     * view causes it to move under the mouse pointer).
     *
     * @param {Selector} popup
     * @param {boolean}  [show]       If *false*, hide the popup.
     */
    function showGalleryDetails(popup, show) {
        var $popup = $(popup);
        if (isMissing($popup)) {
            return;
        }
        if (show || (typeof show === 'undefined')) {
            $popup.addClass(DETAILS_VISIBLE_MARKER);
            $popup[0].scrollIntoView({
                behavior: 'smooth',
                block:    'nearest',
                inline:   'nearest'
            });
        } else {
            $popup.removeClass(DETAILS_VISIBLE_MARKER);
        }
    }

    /**
     * A shortcut for `showGalleryDetails(popup, false)`.
     *
     * @param {Selector} popup
     */
    function hideGalleryDetails(popup) {
        showGalleryDetails(popup, false);
    }

});
