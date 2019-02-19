// app/assets/javascripts/blacklight/search_context.js
//
// This code is essentially unchanged from the original Blacklight source.
// @see https://github.com/projectblacklight/blacklight/blob/v7.0.1/app/javascript/blacklight/search_context.js

(function($) {
    Blacklight.doSearchContextBehavior = function() {
        if (typeof Blacklight.do_search_context_behavior == 'function') {
            console.warn('do_search_context_behavior is deprecated. Use doSearchContextBehavior instead.');
            return Blacklight.do_search_context_behavior();
        }
        $('a[data-context-href]').on('click.search-context',
            Blacklight.handleSearchContextMethod);
    };

    // This is the $.rails.handleMethod with a couple adjustments, described
    // inline: first, we're attaching this directly to the event handler, so
    // we can check for meta-keys.
    Blacklight.handleSearchContextMethod = function(event) {
        if (typeof Blacklight.handle_search_context_method == 'function') {
            console.warn('handle_search_context_method is deprecated. Use handleSearchContextMethod instead.');
            return Blacklight.handle_search_context_method(event);
        }
        var link = $(this);

        // Instead of using the normal href, we need to use the context href.
        var href      = link.data('context-href'),
            method    = 'post',
            target    = link.attr('target'),
            csrfToken = $('meta[name=csrf-token]').attr('content'),
            csrfParam = $('meta[name=csrf-param]').attr('content'),
            form =
                $('<form method="post" action="' + href + '"></form>'),
            metadataInput =
                '<input name="_method" value="' + method +
                '" type="hidden" />',
            redirectHref =
                '<input name="redirect" value="' + link.attr('href') +
                '" type="hidden" />';

        // Check for meta keys.. if set, we should open in a new tab.
        if (event.metaKey || event.ctrlKey) {
            target = '_blank';
        }

        if (csrfParam !== undefined && csrfToken !== undefined) {
            metadataInput +=
                '<input name="' + csrfParam + '" value="' + csrfToken +
                '" type="hidden" />';
        }

        if (target) {
            form.attr('target', target);
        }

        form.hide().append(metadataInput).append(redirectHref)
            .appendTo('body');
        form.submit();

        return false;
    };

    Blacklight.onLoad(function() {
        Blacklight.doSearchContextBehavior();
    });
})(jQuery);
