# lib/blacklight/lens/repository.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/abstract_repository'

module Blacklight::Lens

  # Blacklight::Lens::Repository
  #
  # A subclass of:
  # @see Blacklight::AbstractRepository
  #
  class Repository < Blacklight::AbstractRepository

    include Blacklight::Lens

    DEF_AUTOCOMPLETE_PATH      = 'suggest'
    DEF_AUTOCOMPLETE_SUGGESTER = 'mySuggester'

    # =========================================================================
    # :section: Blacklight::AbstractRepository replacements
    # =========================================================================

    private

    # logger
    #
    # @return [Logger]
    #
    # This method overrides:
    # @see Blacklight::AbstractRepository#logger
    #
    def logger
      @logger ||= Log.logger
    end

    # =========================================================================
    # :section: Blacklight::Solr::Repository replacements
    # =========================================================================

    private

    # suggest_handler_path
    #
    # @return [String]
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#suggest_handler_path
    #
    def suggest_handler_path
      blacklight_config.autocomplete_path || DEF_AUTOCOMPLETE_PATH
    end

    # suggester_name
    #
    # @param [SearchBuilder, Hash, nil]
    #
    # @return [String]
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#suggester_name
    #
    def suggester_name(*)
      blacklight_config.autocomplete_suggester || DEF_AUTOCOMPLETE_SUGGESTER
    end

  end

end

__loading_end(__FILE__)
