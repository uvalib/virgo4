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

    /**
     * Indicate whether a search type must be specified.
     *
     * @const
     * @type {boolean}
     */
    var SEARCH_TYPE_REQUIRED = true;

    /**
     * Default placeholder to display in the search input box.
     *
     * @const
     * @type {string}
     */
    var DEFAULT_PLACEHOLDER = 'Search...';

    /**
     * Placeholder to display when no search type has been selected.
     *
     * @const
     * @type {string}
     */
    var NO_TYPE_PLACEHOLDER = '← Please select a search type';

    /**
     * Search-type-specific placeholders.
     *
     * @const
     * @type {{string:string}}
     */
    var PLACEHOLDER_TABLE = {
        'title':      'Enter a title...',
        'author':     'Enter an author name...',
        'subject':    'Enter subject term(s)...',
        'isbn_issn':  'Enter a standard identifier number...',
        'all_fields': 'Look for terms anywhere within records...'
    };
    if (SEARCH_TYPE_REQUIRED) { PLACEHOLDER_TABLE[''] = NO_TYPE_PLACEHOLDER; }

    /**
     * Default tooltip for the search commit button.
     *
     * @const
     * @type {string}
     */
    var DEFAULT_TOOLTIP = '';

    /**
     * Tooltip to display when no search type has been selected.
     *
     * @const
     * @type {string}
     */
    var NO_TYPE_TOOLTIP = 'Please select a search type';

    /**
     * Search-type-specific tooltips.
     *
     * @const
     * @type {{string:string}}
     */
    var TOOLTIP_TABLE = {};
    if (SEARCH_TYPE_REQUIRED) { TOOLTIP_TABLE[''] = NO_TYPE_TOOLTIP; }

    // ========================================================================
    // Actions
    // ========================================================================

    // Set up the search field for autocomplete.
    //
    // While it's likely that there will only be a single search field on the
    // page that would get typeahead, this is arranged to support an arbitrary
    // number (although that is untested and would probably require additional
    // effort to work properly).
    //
    $('[data-autocomplete-enabled="true"]').not('.tt-hint').each(function() {

        var $search_input  = $(this);
        var suggest_url    = $search_input.data().autocompletePath;
        var no_suggest     = $search_input.data().noSuggest || [];
        var $container     = $search_input.parents('.input-group');
        var $search_field  = $container.find('.search_field');
        var $search_button = $container.find('.search-btn');

        var previous_search_type;
        var terms;

        // ====================================================================
        // Actions
        // ====================================================================

        initializeTypeahead();
        setSearchLabels();

        // ====================================================================
        // Event Handlers
        // ====================================================================

        // When the search type is changed by the user, reinitialize typeahead
        // and display elements for the new search type.
        $search_field.change(function() {
            var search_type = searchType();
            if (search_type !== previous_search_type) {
                initializeTypeahead();
                setSearchLabels();
                previous_search_type = search_type;
            }
            return false;
        });

        // ====================================================================
        // Function definitions - Typeahead
        // ====================================================================

        /**
         * Initialize (or re-initialize) the suggestion engine and typeahead.
         */
        function initializeTypeahead() {
            var reinitialize = !!terms;
            if (reinitialize) {
                $search_input.typeahead('destroy');
            } else {
                terms = buildSuggestionEngine();
            }
            terms.initialize(reinitialize);

            $search_input.typeahead(DEFAULT_OPTIONS, {
                name:    'terms',
                source:  terms.ttAdapter(),
                limit:   SUGGESTION_COUNT,
                display: function(response) { return displayTerm(response); },
                templates: {
                    suggestion: ttEntry,
                    header:     ttHeader,   // TODO: keep?
                    footer:     ttFooter,   // TODO: keep?
                    notFound:   ttNotFound,
                    pending:    ttPending
                }
            });
        }

        /**
         * Set up an instance of the suggestion engine which will modify the
         * final search path based on the currently-selected search type.
         *
         * @returns {Bloodhound}
         */
        function buildSuggestionEngine() {
            return new Bloodhound({
                datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
                queryTokenizer: Bloodhound.tokenizers.whitespace,
                remote: {
                    url: suggest_url,

                    prepare: function(query, settings) {

                        // Settings contains {url: suggest_url, method: 'get',
                        // format: 'json'} Need to return with the URL modified
                        // with the given query.
                        var new_settings = $.extend({}, settings);

                        // Get the search type selected on the menu.
                        var search_type = searchType();

                        // Add the query and search type to the base URL.
                        if (allowAutosuggest(search_type)) {
                            var url = settings.url;
                            url += (url.indexOf('?') === -1) ? '?' : '&';
                            url += 'q=' + query;
                            if (search_type) {
                                url += '&search_field=' + search_type;
                            }
                            new_settings.url = url;
                        } else {
                            new_settings.cancelled = true;
                        }
                        return new_settings;
                    },

                    transport: function(opts, onSuccess, onError) {
                        return allowAutosuggest() &&
                            $.ajax(opts).done(onSuccess).fail(onError);
                    }
                }
            });
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
            return terms && $($.parseHTML(terms)).text();
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
            var result = '';
            if (allowAutosuggest()) {
                result += '<div>' + (data || {}).term + '</div>';
            }
            return result;
        }

        /**
         * Display an informational element at the top of the suggestions menu.
         *
         * @param {object|string} [label]
         *
         * @return {string}
         */
        function ttHeader(label) {
            var search_type;
            var content;
            if (typeof label === 'string') {
                content = label;
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
         * @param {object|string} [label]
         *
         * @return {string}
         */
        function ttFooter(label) {
            var content;
            if (typeof label === 'string') {
                content = label;
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
         * @param {object|string} [label]
         *
         * @return {string}
         */
        function ttNotFound(label) {
            var content;
            if (typeof label === 'string') {
                content = label;
            } else {
                content = 'No suggestions';
            }
            return ttInfo(content, 'tt-notFound', true);
        }

        /**
         * Display an informational element within the suggestions menu while
         * the source is being queried for suggestions.
         *
         * @param {object|string} [label]
         *
         * @return {string}
         */
        function ttPending(label) {
            var content;
            if (!allowAutosuggest()) {
                content = '';
            } else if (typeof label === 'string') {
                content = label;
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
            var element;
            if (allowAutosuggest()) {
                var classes = ['tt-info'];
                if (css_class)                    { classes.push(css_class); }
                if (INFO_SR_ONLY && !always_show) { classes.push('sr-only'); }
                var css = classes.join(' ');
                element = '<div class="' + css + '">' + content + '</div>';
            }
            return element || '';
        }

        // ====================================================================
        // Function definitions - Display
        // ====================================================================

        /**
         * Update the search input box and search button.
         */
        function setSearchLabels() {
            var search_type = searchType();
            updateInputField(search_type);
            updateSearchButton(search_type);
            if (SEARCH_TYPE_REQUIRED) {
                if (isEmpty(search_type)) {
                    $search_button.addClass('disabled');
                } else {
                    $search_button.removeClass('disabled');
                }
            }
        }

        /**
         * Update appearance of the input field based on the search type.
         *
         * @param {string} [search_type]    Default: {@link searchType}().
         */
        function updateInputField(search_type) {
            var label = PLACEHOLDER_TABLE[search_type] || DEFAULT_PLACEHOLDER;
            $search_input.attr('placeholder', label);
        }

        /**
         * Update appearance of the search button based on the search type.
         *
         * @param {string} [search_type]    Default: {@link searchType}().
         */
        function updateSearchButton(search_type) {
            var tooltip = TOOLTIP_TABLE[search_type] || DEFAULT_TOOLTIP;
            $search_button.attr('title', tooltip);
        }

        // ====================================================================
        // Function definitions - General
        // ====================================================================

        /**
         * Indicate whether autosuggest should happen for the currently
         * selected search type.
         *
         * @param {string} [search_type]    Default: {@link searchType}().
         *
         * @return {boolean}
         */
        function allowAutosuggest(search_type) {
            var t = search_type || searchType();
            var off = noSearchTypeSelected(t) || (no_suggest.indexOf(t) >= 0);
            return !off;
        }

        /**
         * If SEARCH_TYPE_REQUIRED is *true*, indicate whether no search type
         * has been selected.
         *
         * @param {string} [search_type]  Default: {@link searchType}()
         *
         * @return {boolean}
         */
        function noSearchTypeSelected(search_type) {
            return SEARCH_TYPE_REQUIRED && isEmpty(search_type || searchType());
        }

        /**
         * The currently selected search type.
         *
         * @return {string}
         */
        function searchType() {
            return $search_field.val();
        }

    });

});
