// app/assets/feature/log.js
//
// Adds functionality to Blacklight::Gallery.

Blacklight.onLoad(function() {

    // Only perform these actions on the appropriate pages.
    var $scroller = $('.log-scroller');
    if (isMissing($scroller)) { return; }

    // ========================================================================
    // Actions
    // ========================================================================

    // Ensure that a click anywhere on the button causes a submit.  Without
    // this, only clicks on the text of the label (the <input> element) would
    // activate the button.
    $('.log-button').click(function(event) {
        var $this = $(this);
        var $input = $this.find('input[type="submit"]');
        event.target = $input[0];
        event.stopPropagation();
        $input.trigger(event);
        return false;
    });

    // Initialize the display to the end of the file.
    logScrollToBottom();

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Ensure the first column of the last line of the contents is visible.
     */
    function logScrollToBottom() {
        var parent     = $scroller.parent()[0];
        var scroller   = $scroller[0];
        var bar_height = parent.offsetHeight - scroller.offsetHeight;
        scroller.scrollLeft = 0;
        scroller.scrollTop  = scroller.scrollHeight - bar_height;
    }

});
