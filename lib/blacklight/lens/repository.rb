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

    # The search repository URL path for autosuggest results.
    #
    # @return [String]
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#suggest_handler_path
    #
    def suggest_handler_path
      blacklight_config.autocomplete_path || DEF_AUTOCOMPLETE_PATH
    end

    # The search repository autosuggest handler modified by the presence of
    # :search_field in the supplied parameters.
    #
    # @param [SearchBuilder, Hash, nil] url_params
    #
    # @return [String]
    # @return [nil]                   If autosuggest should not be performed.
    #
    # Compare with:
    # @see Blacklight::Solr::Repository#suggester_name
    #
    def suggester_name(url_params = nil)
      cfg = blacklight_config
      default      = cfg.autocomplete_suggester  || DEF_AUTOCOMPLETE_SUGGESTER
      suggester    = cfg.autocomplete_suggest    || {}
      no_suggester = cfg.autocomplete_no_suggest || {}
      search_type  = (url_params && url_params[:search_field]).to_s
      result =
        case search_type
          when '', 'all_fields' then default
          else                       make_suggester_name(search_type)
        end
      if no_suggester.include?(result)
        nil
      elsif !suggester.include?(result)
        logger.warn("invalid suggester #{result.inspect}")
        default
      else
        result
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # Map a search type to its search repository suggester.
    #
    # @param [String] search_type
    #
    # @return [String]
    #
    def make_suggester_name(search_type)
      search_type.to_s
    end

  end

end

__loading_end(__FILE__)
