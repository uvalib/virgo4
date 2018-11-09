// app/assets/javascripts/blacklight/autocomplete.js
//
// This code has been modified from the original Blacklight source in order to
// support switching the suggester based on the currently selected search type.
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
        var $search_field = $('#search_field');
        var previous_search_type;

        // Set up the suggestion engine to modify the final path based on the
        // currently-selected search type.
        var terms = new Bloodhound({
            datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
            queryTokenizer: Bloodhound.tokenizers.whitespace,
            remote: {
                url:     suggest_url,
                prepare: function(query, settings) {

                    // Settings contains {url: suggest_url, method: 'get',
                    // format: 'json'} Need to return with the URL modified
                    // with the given query.
                    var new_settings = $.extend({}, settings);

                    // Add the query to the base URL.
                    var url = settings.url;
                    url += (url.indexOf('?') === -1) ? '?' : '&';
                    url += 'q=' + query;

                    // Determine which search type has been selected on the
                    // menu. If the type has changed, clear the cache so that
                    // the appropriate set of information is searched rather
                    // than accepting cached values that probably are not
                    // appropriate.  NOTE: Is there a way to save and restore
                    // the cache? If so, the cache could be saved when
                    // switching to a new search type and then restored when
                    // that search type is selected again.
                    var search_type = $search_field.val();
                    if (search_type !== previous_search_type) {
                        terms.clear();
                        previous_search_type = search_type;
                    }
                    if (search_type) {
                        url += '&search_field=' + search_type;
                    }

                    // Return with the finalized search URL.
                    new_settings.url = url;
                    return new_settings;
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
                suggestion: ttEntry, // function reference not function call
                header:     ttHeader,       // TODO: comment out, probably
                footer:     ttFooter(),     // TODO: comment out, probably
                notFound:   ttNotFound(),   // TODO: comment out?
                pending:    ttPending(),    // TODO: comment out?
            }
        });

    });

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * Process a suggestion entry to remove highlighting that Solr may add.
     *
     * This is necessary to eliminate the <b></b> tags from the string used to
     * load into the search input element is updated from the selected
     * suggestion.
     *
     * @param {object} data
     *
     * @return {string}
     */
    function displayTerm(data) {
        data = data || {};
        return data.term.toString().replace(/<\/?b>/g, '');
    }

    /**
     * Render a suggestions menu entry.
     *
     * Note that for Solr results, this does not remove the <b></b> tags, so
     * suggestion menu entries will have hit highlighting of the form
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
        return '<div>' + data.term + '</div>';
    }

    /**
     * Display an informational element at the top of the suggestions menu.
     *
     * @param {string} [content]
     *
     * @return {string}
     */
    function ttHeader(content) {
        if (typeof content !== 'string') {
            var search_type = $('#search_field').val();
            if (search_type) {
                content = 'Suggested ' + search_type + ' searches';
            } else {
                content = 'Suggested search terms';
            }
        }
        content = '&mdash;' + content + '&mdash;';
        return ttInfo(content, 'tt-header');
    }

    /**
     * Display an informational element at the bottom of the suggestions menu.
     *
     * @param {string} [content]
     *
     * @return {string}
     */
    function ttFooter(content) {
        if (typeof content !== 'string') {
            content = 'END';
        }
        content = '&mdash;' + content + '&mdash;';
        return ttInfo(content, 'tt-footer');
    }

    /**
     * Display an informational element within the suggestions menu if no
     * suggestions were retrieved from the source.
     *
     * @param {string} [content]
     *
     * @return {string}
     */
    function ttNotFound(content) {
        if (typeof content !== 'string') {
            content = 'No suggestions';
        }
        return ttInfo(content, 'tt-notFound', true);
    }

    /**
     * Display an informational element within the suggestions menu while
     * the source is being queried for suggestions.
     *
     * @param {string|object} [content]
     *
     * @return {string}
     */
    function ttPending(content) {
        if (typeof content !== 'string') {
            var src = LOADING_IMAGE;
            var alt = 'Looking...';
            content = '<img src="' + src + '" alt="' + alt + '">';
        }
        return ttInfo(content, 'tt-pending', true);
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
        return '<div class="' + classes.join(' ') + '">' + content + '</div>';
    }

});
