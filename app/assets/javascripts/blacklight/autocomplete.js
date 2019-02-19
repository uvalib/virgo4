// app/assets/javascripts/blacklight/autocomplete.js
//
// This code has been modified from the original Blacklight source in order to
// support switching the suggester based on the currently selected search type.
//
// Compare with:
// @see https://github.com/projectblacklight/blacklight/blob/v7.0.1/app/javascript/blacklight/autocomplete.js
//
// Twitter Typeahead for autocomplete
//= require twitter/typeahead
//= require shared/assets

// Overrides the provided Blacklight code in order to change to the arguments
// to "suggest" based on the type of search selected.
//
// @see https://github.com/twitter/typeahead.js/blob/master/doc/jquery_typeahead.md
// @see https://digitalfortress.tech/tutorial/smart-search-using-twitter-typeahead-bloodhound/
//
Blacklight.onLoad(function() {

    'use strict';

    /**
     * Typeahead defaults.
     *
     * @type {{
     *      highlight:  boolean,
     *      hint:       boolean,
     *      minLength:  number
     *  }}
     */
    var DEFAULT_OPTIONS = {
        highlight: true,    // Wrap matches with <strong> in the results.
        hint:      false,   // Don't pre-fill search bar placeholder.
        minLength: 2        // Start showing suggestions after this many chars.
    };

    /**
     * Show this many suggestions.  5 is the Twitter Typeahead default.
     *
     * This should agree with:
     * @see Blacklight::Solr::RepositoryExt#SUGGESTION_COUNT
     *
     * @const
     * @type {number}
     */
    var SUGGESTION_COUNT = 7;

    /**
     * Added informational entries may or may not be desirable visual elements,
     * but they can also serve as screen reader landmarks. Set this to *true*
     * if they will only be visible to screen readers.
     *
     * @const
     * @type {boolean}
     */
    var INFO_SR_ONLY = false;

    // ========================================================================
    // Actions
    // ========================================================================

    $('[data-autocomplete-enabled="true"]').not('.tt-hint').each(function() {

        var $this         = $(this);
        var suggest_url   = $this.data().autocompletePath;
        var no_suggest    = $this.data().noSuggest || [];
        var $search_field = $('#search_field');
        var previous_search_type;

        // Set up the suggestion engine to modify the final path based on the
        // currently-selected search type.
        var terms = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url: suggest_url,

                prepare: function(query, settings) {

                    // Settings contains {url: suggest_url, method: 'get',
                    // format: 'json'} Need to return with the URL modified
                    // with the given query.
                    var new_settings = $.extend({}, settings);

                    // Get the search type that has been selected on the menu.
                    var search_type = searchType();

                    if (noAutosuggest(search_type)) {

                        // If this is a search type that should not support
                        // typeahead, pass a flag to the transport function.
                        new_settings.cancelled = true;

                    } else {

                        // If the search type has changed, clear the cache so
                        // that the appropriate set of information is searched
                        // rather than accepting cached values that probably
                        // are not appropriate.
                        if (search_type !== previous_search_type) {
                            terms.clear();
                            previous_search_type = search_type;
                        }

                        // NOTE: Is there a way to save and restore the cache?
                        // If so, the cache could be saved when switching to a
                        // new search type and then restored when that search
                        // type is selected again.

                        // Add the query and search type to the base URL.
                        var url = settings.url;
                        url += (url.indexOf('?') === -1) ? '?' : '&';
                        url += 'q=' + query;
                        if (search_type) {
                            url += '&search_field=' + search_type;
                        }
                        new_settings.url = url;
                    }
                    return new_settings;
                },

                transport: function(opts, onSuccess, onError) {
                    if (!opts.cancelled) {
                        $.ajax(opts).done(onSuccess).fail(onError);
                    }
                }
            }
        });

        terms.initialize();

        $this.typeahead(DEFAULT_OPTIONS, {
            name:       'terms',
            source:     terms.ttAdapter(),
            limit:      SUGGESTION_COUNT,
            display:    function(response) { return displayTerm(response); },
            templates: {
                suggestion: ttEntry,
                header:     ttHeader,   // TODO: keep?
                footer:     ttFooter,   // TODO: keep?
                notFound:   ttNotFound,
                pending:    ttPending
            }
        });

        // ====================================================================
        // Function definitions
        // ====================================================================

        /**
         * The currently selected search type.
         *
         * @return {string}
         */
        function searchType() {
            return $search_field.val();
        }

        /**
         * Indicate whether autosuggest should happen for the currently
         * selected search type.
         *
         * @param {string} [search_type]    Default: value of $search_field.
         *
         * @return {boolean}
         */
        function noAutosuggest(search_type) {
            var type = search_type || searchType();
            return (no_suggest.indexOf(type) >= 0);
        }

        /**
         * Process a suggestion entry to remove highlighting that Solr may add.
         *
         * This is necessary to sanitize the string (including eliminating the
         * <b></b> inserted by Solr) which is used to update the search input
         * element with the selected suggestion.
         *
         * @param {object} data
         *
         * @return {string}
         */
        function displayTerm(data) {
            var terms = ttEntry(data);
            return $($.parseHTML(terms)).text();
        }

        /**
         * Render a suggestions menu entry.
         *
         * Note that for Solr results, this does not remove the <b></b> tags,
         * so suggestion menu entries will have hit highlighting of the form
         *
         *  <b><strong class="tt-highlight">INPUT_WORD</strong></b>
         *
         * where INPUT_WORD is the portion of the (single) search term that the
         * user has entered (so far).  To avoid "over-bolding" use CSS styling:
         *
         *  .tt-suggestion b strong { font-weight: bold }
         *
         * since both <b> and <strong> have "font-weight: bolder;" normally.
         *
         * @param {object} data
         *
         * @return {string}
         */
        function ttEntry(data) {
            return '<div>' + (data || {}).term + '</div>';
        }

        /**
         * Display an informational element at the top of the suggestions menu.
         *
         * @param {object|string} [query]
         *
         * @return {string}
         */
        function ttHeader(query) {
            var search_type;
            var content;
            if (typeof query === 'string') {
                content = query;
            } else if (search_type = searchType()) {
                content = 'Suggested ' + search_type + ' searches';
            } else {
                content = 'Suggested search terms';
            }
            content = '&mdash;' + content + '&mdash;';
            return ttInfo(content, 'tt-header');
        }

        /**
         * Display an informational element at the bottom of the suggestions
         * menu.
         *
         * @param {object|string} [query]
         *
         * @return {string}
         */
        function ttFooter(query) {
            var content;
            if (typeof query === 'string') {
                content = query;
            } else {
                content = 'END';
            }
            content = '&mdash;' + content + '&mdash;';
            return ttInfo(content, 'tt-footer');
        }

        /**
         * Display an informational element within the suggestions menu if no
         * suggestions were retrieved from the source.
         *
         * @param {object|string} [query]
         *
         * @return {string}
         */
        function ttNotFound(query) {
            var content;
            if (typeof query === 'string') {
                content = query;
            } else {
                content = 'No suggestions';
            }
            return ttInfo(content, 'tt-notFound', true);
        }

        /**
         * Display an informational element within the suggestions menu while
         * the source is being queried for suggestions.
         *
         * @param {object|string} [query]
         *
         * @return {string}
         */
        function ttPending(query) {
            var content;
            if (noAutosuggest()) {
                content = '';
            } else if (typeof query === 'string') {
                content = query;
            } else {
                var src = LOADING_IMAGE;
                var alt = 'Looking...';
                content = '<img src="' + src + '" alt="' + alt + '">';
                content = ttInfo(content, 'tt-pending', true);
            }
            return content;
        }

        /**
         * Display an informational element within the suggestions menu.
         *
         * @param {string}  [content]
         * @param {string}  [css_class]
         * @param {boolean} [always_show]   If *true*, make visible even if
         *                                      INFO_SR_ONLY is *true*.
         *
         * @return {string}
         */
        function ttInfo(content, css_class, always_show) {
            var classes = ['tt-info'];
            if (css_class)                    { classes.push(css_class); }
            if (INFO_SR_ONLY && !always_show) { classes.push('sr-only'); }
            var css = classes.join(' ');
            return '<div class="' + css + '">' + content + '</div>';
        }

    });

});
