# config/initializers/_extensions.rb
#
# frozen_string_literal: true
# warn_indent:           true

# Extensions to classes that need to be established as soon as possible during
# initialization.
require Rails.root.join('lib/ext').to_path

=begin # TODO: Strong parameters?
# NOTE: Strong parameters don't seem to be useful quite yet...
ActionController::Parameters.permit_all_parameters = true
=end
