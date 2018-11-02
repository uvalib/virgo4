# lib/blacklight/eds/search_state.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require 'blacklight/lens/search_state'

module Blacklight::Eds

  # Redefine Blacklight::SearchState for lens-sensitivity.
  #
  # @see Blacklight::Lens::SearchState
  #
  class SearchState < Blacklight::Lens::SearchState

    # TODO: ???

  end

end

__loading_end(__FILE__)
