// app/assets/javascripts/blacklight/autocomplete.js

/*global Bloodhound */

// Overrides the provided Blacklight code in order to change to the arguments
// to "suggest" based on the type of search selected.
Blacklight.onLoad(function() {

    'use strict';

    $('[data-autocomplete-enabled="true"]').not('.tt-hint').each(function() {

        var $this         = $(this);
        var suggest_url   = $this.data().autocompletePath;
        var $search_field = $('#search_field');

        // Set up the suggestion engine to modify the final path based on the
        // currently-selected search type.
        var previous_search;
        var terms = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url:      suggest_url,
                wildcard: '%QUERY',
                prepare:  function(search_terms, settings) {

                    // Settings contains {url: suggest_url, method: 'get',
                    // format: 'json'} Need to return with the URL modified
                    // with the given query.
                    var new_settings = $.extend({}, settings);

                    // Add the query to the base URL.
                    var url = settings.url;
                    url += (url.indexOf('?') > 0) ? '&' : '?';
                    url += 'q=' + search_terms;

                    // Determine which search type has been selected on the
                    // menu. If the type has changed, clear the cache so that
                    // the appropriate set of information is searched rather
                    // than accepting cached values that probably are not
                    // appropriate.  NOTE: Is there a way to save and restore
                    // the cache? If so, the cache could be saved when
                    // switching to a new search type and then restored when
                    // that search type is selected again.
                    var selected_search = $search_field.find(':selected').val();
                    if (selected_search !== previous_search) {
                        terms.clear();
                        previous_search = selected_search;
                    }
                    if (selected_search) {
                        url += '&search_field=' + selected_search;
                    }

                    // Return with the finalized search URL.
                    new_settings.url = url;
                    return new_settings;
                }
            }
        });
        terms.initialize();

        $this.typeahead({
            hint:      true,
            highlight: true,
            minLength: 2
        }, {
            name:       'terms',
            displayKey: 'term',
            source:     terms.ttAdapter()
        });

    });

});
