// app/assets/javascripts/blacklight/checkbox_submit.js

/* A JQuery plugin (should this be implemented as a widget instead? not sure)
   that will convert a "toggle" form, with single submit button to add/remove
   something, like used for Bookmarks, into an AJAXy checkbox instead.

   Apply to a form. Does require certain assumption about the form:
    1) The same form 'action' href must be used for both ADD and REMOVE
       actions, with the different being the hidden input name="_method"
       being set to "put" or "delete" -- that's the Rails method to pretend
       to be doing a certain HTTP verb. So same URL, PUT to add, DELETE
       to remove. This plugin assumes that.

       Plus, the form this is applied to should provide a data-doc-id
       attribute (HTML5-style doc-*) that contains the id/primary key
       of the object in question -- used by plugin for a unique value for
       DOM id's.

  Uses HTML for a checkbox compatible with Bootstrap 3.

   Pass in options for your class name and labels:
   $("form.something").bl_checkbox_submit({
        checked_label: "Selected",
        unchecked_label: "Select",
        progress_label: "Saving...",
        //css_class is added to elements added, plus used for id base
        css_class: "toggle_my_kinda_form",
        success: function(after_success_check_state) {
          #optional callback
        }
   });
*/
(function($) {

    $.fn.bl_checkbox_submit = function(arg_opts) {

        var options = $.extend({}, $.fn.bl_checkbox_submit.defaults, arg_opts);

        this.each(function() {

            var $form = $(this);
            $form.children().hide();

            // We're going to use the existing form to actually send our
            // add/removes.  This works conveniently because the exact same
            // action href is used for both bookmarks/$doc_id.  But let's take
            // out the irrelevant parts of the form to avoid any future
            // confusion.
            $form.find('input[type=submit]').remove();
            $form.addClass('form-horizontal');

            // View needs to set data-doc-id so we know a unique value for
            // making DOM id.
            var unique_id = $form.attr('data-doc-id') || Math.random();
            unique_id = options.css_class + '_' + unique_id;

            var $checkbox = $('<input type="checkbox">')
                .addClass(options.css_class)
                .attr('id', unique_id);

            var $span = $('<span>');

            var $label = $('<label>')
                .addClass(options.css_class)
                .attr('for', unique_id)
                .attr('title', ($form.attr('title') || ''))
                .append($checkbox)
                .append(' ')
                .append($span);

            var $checkbox_div = $('<div class="checkbox" />')
                .addClass(options.css_class)
                .append($label);

            $form.append($checkbox_div);

            // If the form is currently using method delete to change state,
            // then the checkbox is currently checked.
            var checked =
                ($form.find('input[name=_method][value=delete]').length != 0);

            // Set the Rails hidden field that fakes an HTTP verb properly
            // for current state action.
            function update_state_for(state) {
                $label.toggleClass('checked', state);
                $checkbox.prop('checked', state);
                var method = state ? 'delete' : 'put';
                var attr   = state ? 'data-present' : 'data-absent';
                $form.find('input[name=_method]').val(method);
                $span.text($form.attr(attr));
            }

            update_state_for(checked);

            $checkbox.click(function() {

                $label.attr('disabled', 'disabled');
                $checkbox.attr('disabled', 'disabled');
                $span.text($form.attr('data-inprogress'));

                $.ajax({
                    url:      $form.attr('action'),
                    type:     $form.attr('method').toUpperCase(),
                    dataType: 'json',
                    data:     $form.serialize(),

                    error: function() {
                        $label.removeAttr('disabled');
                        $checkbox.removeAttr('disabled');
                        update_state_for(checked);
                        alert('Error');
                    },

                    success: function(data, status, xhr) {
                        $label.removeAttr('disabled');
                        $checkbox.removeAttr('disabled');
                        // If app isn't running at all, XHR annoyingly reports
                        // success with status 0.
                        if (xhr.status === 0) {
                            update_state_for(checked);
                            alert('Error');
                        } else {
                            checked = !checked;
                            update_state_for(checked);
                            options.success.call($form, checked,
                                xhr.responseJSON);
                        }
                    }
                });
                return false;
            });
        });
        return this;
    };

    // css_class is added to elements added, plus used for id base
    $.fn.bl_checkbox_submit.defaults = {
        css_class:  'bl_checkbox_submit',
        success:    function() {} // callback
    };
})(jQuery);
