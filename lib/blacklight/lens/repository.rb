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
    # :section: Blacklight::Solr::Repository replacements
    # =========================================================================

    private

    # suggest_handler_path
    #
    # @return [String]
    #
    def suggest_handler_path
      blacklight_config.autocomplete_path || DEF_AUTOCOMPLETE_PATH
    end

    # suggester_name
    #
    # @return [String]
    #
    def suggester_name
      blacklight_config.autocomplete_suggester || DEF_AUTOCOMPLETE_SUGGESTER
    end

  end

end

__loading_end(__FILE__)
