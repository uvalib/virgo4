// app/assets/javascripts/shared/definitions.js

/** @type {number} */
var LOAD_TIME;

if (!LOAD_TIME) {

    LOAD_TIME = Date.now();

    // ========================================================================
    // Basic values and enumerations
    // ========================================================================

    /**
     * Multiply by this to indicate that the a quantity represents a time span
     * in milliseconds.
     *
     * @constant
     * @type {number}
     */
    var MILLISECONDS = 1;

    /**
     * @constant
     * @type {number}
     */
    var MS_PER_SECOND = 1000 * MILLISECONDS;

    /**
     * Multiply by this to indicate that the a quantity represents a time span
     * in seconds.
     *
     * @constant
     * @type {number}
     */
    var SECONDS = MS_PER_SECOND;

    /**
     * @constant
     * @type {number}
     */
    var SEC_PER_MINUTE = 60 * SECONDS;

    /**
     * Multiply by this to indicate that the a quantity represents a time span
     * in minutes.
     *
     * @constant
     * @type {number}
     */
    var MINUTES = SEC_PER_MINUTE;

    // ========================================================================
    // JSDoc typedefs
    // ========================================================================

    /**
     * Indicates a function parameter that expects a {@link jQuery} object or
     * something that can be used to generate a {@link jQuery} object.
     *
     * @typedef Selector
     * @type {string|HTMLElement|jQuery}
     */
    var Selector;

    // ========================================================================
    // Function definitions - Time and date
    // ========================================================================

    /**
     * Milliseconds since the given time.
     *
     * @param {number} timestamp      Original `Date.now()` value.
     *
     * @return {number}
     */
    function delta(timestamp) {
        return Date.now() - timestamp;
    }

    /**
     * Seconds since the given time.
     *
     * @param {number} timestamp      Original `Date.now()` value.
     *
     * @return {number}
     */
    function secondsSince(timestamp) {
        return delta(timestamp) / MS_PER_SECOND;
    }

    // ========================================================================
    // Function definitions - Element values
    // ========================================================================

    /**
     * Indicate whether the item is not undefined.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function isDefined(item) {
        return typeof item !== 'undefined';
    }

    /**
     * Indicate whether the item is not defined.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function notDefined(item) {
        return !isDefined(item);
    }

    /**
     * Indicate whether the item does not contain a value.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function isEmpty(item) {
        if (!item) {
            return true;
        } else if (isDefined(item.length)) {
            return !item.length;
        } else if (typeof item === 'object') {
            for (var property in item) {
                if (item.hasOwnProperty(property)) {
                    return false;
                }
            }
            return true;
        }
        return false;
    }

    /**
     * Indicate whether the item contains a value.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function notEmpty(item) {
        return !isEmpty(item);
    }

    /**
     * Indicate whether the item does not contain a value.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function isMissing(item) {
        return isEmpty(item);
    }

    /**
     * Indicate whether the item contains a value.
     *
     * @param {*} item
     *
     * @return {boolean}
     */
    function isPresent(item) {
        return !isMissing(item);
    }
}
