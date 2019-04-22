// app/assets/javascripts/feature/availability.js

/**
 * Availability feature: Display availability of catalog entries via summary
 * status values on index pages and holdings tables on show pages.
 *
 * @type {object}
 *
 * @property {function} monitorStatus
 * @property {function} monitorHoldings
 * @property {function} updateStatus
 * @property {function} updateHoldings
 * @property {function} defaultRoot
 */
var Availability = (function() {

    // ========================================================================
    // Constants
    // ========================================================================

    /**
     * Abort an AJAX request if it is not completed within this time limit.
     *
     * @constant
     * @type {number}
     */
    var AVAILABILITY_TIMEOUT = 5 * SECONDS;

    /**
     * Re-acquire data after this span of time (even on elements which include
     * the {@link COMPLETE_MARKER} class).
     *
     * @constant
     * @type {number}
     */
    var DATA_EXPIRATION = 5 * MINUTES;

    /**
     * Selector for index availability status elements.
     *
     * @constant
     * @type {string}
     */
    var INDEX_SELECTOR = '.availability-status';

    /**
     * Selector for the show page holdings table.
     *
     * @constant
     * @type {string}
     */
    var SHOW_SELECTOR = '.holdings';

    /**
     * An element already contains ILS data if it has this CSS class.
     *
     * @constant
     * @type {string}
     */
    var COMPLETE_MARKER = 'complete';

    /**
     * The property used to store the time of data acquisition for an element.
     *
     * @constant
     * @type {string}
     */
    var TIMESTAMP_ATTR = 'timestamp';

    /**
     * Message displayed in place of received data when there was a failure to
     * receive data.
     *
     * @constant
     * @type {string}
     */
    var FAILURE_MESSAGE = 'Item status is temporarily unavailable.';

    // ========================================================================
    // Variables
    // ========================================================================

    /**
     * Handle for the index page status monitor (if active).
     *
     * @type {number|undefined}
     *
     * @see monitorStatus
     */
    var status_timeout;

    /**
     * Handle for the show page holdings monitor (if active).
     *
     * @type {number|undefined}
     *
     * @see monitorHoldings
     */
    var holdings_timeout;

    // ========================================================================
    // Internal function definitions
    // ========================================================================

    /**
     * Add a timestamp attribute.
     *
     * @param {jQuery} $element
     */
    function timeStamp($element) {
        $element.attr(TIMESTAMP_ATTR, Date.now());
    }

    /**
     * Retrieve a timestamp attribute.
     *
     * @param {jQuery} $element
     *
     * @return {number}               NaN if the timestamp is missing.
     */
    function timeStampOf($element) {
        return Number($element.attr(TIMESTAMP_ATTR));
    }

    /**
     * Indicate whether the target should be (re-)acquired from the service.
     *
     * @param {jQuery} $target
     *
     * @return {boolean}
     */
    function shouldFetch($target) {
        return !$target.hasClass(COMPLETE_MARKER) ||
            (delta(timeStampOf($target)) >= DATA_EXPIRATION);
    }

    /**
     * Acquire availability information via an AJAX call.
     *
     * @param {jQuery} $target
     * @param {string} path
     * @param {string} [caller]       Name of calling function.
     */
    function fetchData($target, path, caller) {
        var _func_ = caller || 'fetchData';
        var start;
        $.ajax({
            url:      path,
            type:     'GET',
            dataType: 'html',
            timeout:  AVAILABILITY_TIMEOUT,

            /**
             * Actions before the request is sent.
             *
             * @param {XMLHttpRequest} xhr
             * @param {object}         settings
             */
            beforeSend: function(xhr, settings) {
                //console.log(_func_, path, 'beforeSend');
                start = Date.now();
            },

            /**
             * Replace the contents of the target element with the contents of
             * the received HTML element.
             *
             * @param {object}         data
             * @param {string}         status
             * @param {XMLHttpRequest} xhr
             */
            success: function(data, status, xhr) {
                //console.log(_func_, path, 'GET', secondsSince(start), 'sec');
                var tgt_id = $target.attr('id');
                var rcv_id;
                var data_html = data.replace(/id="[^"]*"/, function(id_attr) {
                    rcv_id = id_attr.replace('id="', '').replace('"', '');
                    return 'id="new_' + rcv_id + '"';
                });
                if (tgt_id === rcv_id) {
                    $target.empty().addClass(COMPLETE_MARKER);
                    var $content = $(data_html).children();
                    if ($content.text()) {
                        // Replace the contents of the target element with the
                        // contents of the received HTML element.
                        $target.append($content);
                    } else {
                        // A valid but blank result indicates that the catalog
                        // entry is online-only, so availability status does
                        // not need to be shown at all.
                        var $dd = $target.parents('dd.availability');
                        var $dt = $dd.siblings('dt.availability');
                        $dd.addClass('hidden');
                        $dt.addClass('hidden');
                    }
                } else {
                    var received = 'received id #' + rcv_id;
                    var expected = 'target id #'   + tgt_id;
                    console.error(_func_, path, received, '!=', expected);
                }
            },

            /**
             * Note failures on the console and the display.
             *
             * @param {XMLHttpRequest} xhr
             * @param {string}         status
             * @param {string}         error
             */
            error: function(xhr, status, error) {
                //console.log(_func_, path, 'FAIL', secondsSince(start), 'sec');
                $target
                    .removeClass(COMPLETE_MARKER)
                    .removeAttr(TIMESTAMP_ATTR)
                    .html(FAILURE_MESSAGE);
                console.warn(_func_ + ':', status + ':', error);
            }
        });
    }

    /**
     * Acquire an index availability indicator via an AJAX call.
     *
     * @param {Selector} selector
     */
    function fetchStatus(selector) {
        var $target = $(selector);
        var id      = $target.attr('id').split('availability_')[1];
        var path    = '/availability?id=' + id;
        fetchData($target, path, 'fetchStatus');
    }

    /**
     * Acquire holdings availability information via an AJAX call.
     *
     * @param {Selector} selector
     */
    function fetchHoldings(selector) {
        var $target = $(selector);
        var id      = $target.attr('id').split('holdings_')[1];
        var path    = '/availability/' + id;
        fetchData($target, path, 'fetchHoldings');
    }

    // ========================================================================
    // Function definitions
    // ========================================================================

    /**
     * defaultRoot
     *
     * @return {jQuery}
     */
    function defaultRoot() {
        return $('body');
    }

    /**
     * Acquire index availability indicators as needed.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [selector]   Default: {@link INDEX_SELECTOR}
     *
     * @return {number}               The number of matching elements.
     */
    function updateStatus(root, selector) {
        //console.log('updateStatus');
        var $root     = root ? $(root) : defaultRoot();
        var $elements = $root.find(selector || INDEX_SELECTOR);
        $elements.each(function() {
            var $this = $(this);
            if (shouldFetch($this))  { fetchStatus($this); }
            if (!timeStampOf($this)) { timeStamp($this); }
        });
        return $elements.length;
    }

    /**
     * Acquire holdings availability information as needed.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [selector]   Default: {@link SHOW_SELECTOR}
     *
     * @return {number}               The number of matching elements.
     */
    function updateHoldings(root, selector) {
        //console.log('updateHoldings');
        var $root     = root ? $(root) : defaultRoot();
        var $elements = $root.find(selector || SHOW_SELECTOR);
        $elements.each(function() {
            var $this = $(this);
            if (shouldFetch($this))  { fetchHoldings($this); }
            if (!timeStampOf($this)) { timeStamp($this); }
        });
        return $elements.length;
    }

    /**
     * Acquire index availability indicators now and after every
     * {@link DATA_EXPIRATION} interval.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [selector]   Default: {@link INDEX_SELECTOR}
     *
     * @see status_timeout
     */
    function monitorStatus(root, selector) {
        //console.log('monitorStatus');
        var update = function () {
            //console.log('monitorStatus - update');
            clearTimeout(status_timeout);
            status_timeout = undefined;
            return updateStatus(root, selector);
        };
        if (update()) {
            status_timeout = setTimeout(update, DATA_EXPIRATION);
        }
    }

    /**
     * Acquire holdings availability information now and after every
     * {@link DATA_EXPIRATION} interval.
     *
     * @param {Selector} [root]       Default: {@link defaultRoot}()
     * @param {Selector} [selector]   Default: {@link SHOW_SELECTOR}
     *
     * @see holdings_timeout
     */
    function monitorHoldings(root, selector) {
        //console.log('monitorHoldings');
        var update = function () {
            //console.log('monitorHoldings - update');
            clearTimeout(holdings_timeout);
            holdings_timeout = undefined;
            return updateHoldings(root, selector);
        };
        if (update()) {
            holdings_timeout = setTimeout(update, DATA_EXPIRATION);
        }
    }

    // ========================================================================
    // Feature initialization
    // ========================================================================

    $(document).ready(function() {
        //console.log('AVAILABILITY');
    });

    // ========================================================================
    // Exposed definitions
    // ========================================================================

    return {
        monitorStatus:   monitorStatus,
        monitorHoldings: monitorHoldings,
        updateStatus:    updateStatus,
        updateHoldings:  updateHoldings,
        defaultRoot:     defaultRoot
    };

})();
