# lib/ext/blacklight/parameters_override.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/parameters'

NON_SEARCH_PARAMS = %i(controller action id commit utf8)

# =============================================================================
# :section: Blacklight::Parameters overrides
# =============================================================================

module Blacklight

  module Parameters

    # Sanitize by removing parameters not needed for search.
    #
    # @param [ActionController::Parameters, Hash] params
    #
    # @return [Hash]
    #
    def self.sanitize(params)
      params = params.to_unsafe_h if params.respond_to?(:to_unsafe_h)
      params.reject { |_, v| v.blank? }.except(*NON_SEARCH_PARAMS)
    end

  end

end

__loading_end(__FILE__)
