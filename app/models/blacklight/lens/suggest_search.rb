# app/models/blacklight/lens/suggest_search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::SuggestSearch
  #
  class SuggestSearch < Blacklight::SuggestSearch

    # =========================================================================
    # :section: Blacklight::SuggestSearch overrides
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [ActionController::Parameters, Hash] params
    # @param [Blacklight::AbstractRepository]     repository
    #
    def initialize(params, repository)
      params = params.to_unsafe_h if params.is_a?(ActionController::Parameters)
      @request_params = params.slice(:q, :search_field)
      @repository     = repository
    end

  end

end

__loading_end(__FILE__)
