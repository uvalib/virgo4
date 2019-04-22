// app/assets/javascripts/catalog/index.js

Blacklight.onLoad(function() {

    // Only perform these actions on the appropriate pages.
    if (!$('body').hasClass('blacklight-catalog-index')) { return; }

    // ========================================================================
    // Actions
    // ========================================================================

    Availability.monitorStatus();

});
