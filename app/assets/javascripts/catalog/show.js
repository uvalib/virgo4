// app/assets/javascripts/catalog/show.js

Blacklight.onLoad(function() {

    // Only perform these actions on the appropriate pages.
    if (!$('body').hasClass('blacklight-catalog-show')) { return; }

    // ========================================================================
    // Actions
    // ========================================================================

    Availability.monitorHoldings();

});
