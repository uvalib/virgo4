# lib/blacklight_advanced_search/advanced_query_parser_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight_advanced_search/advanced_query_parser'

module BlacklightAdvancedSearch

  # Can extract query elements from rails #params query params, and then parse
  # them and convert them into a solr query with #to_solr
  #
  # #keyword_queries and #filters, which just return extracted elements of
  # query params, may also be useful in display etc.
  #
  # @see BlacklightAdvancedSearch::QueryParser
  #
  class QueryParserExt < BlacklightAdvancedSearch::QueryParser

    # =========================================================================
    # :section: BlacklightAdvancedSearch::QueryParser overrides
    # =========================================================================

    public

    # Initialize a self instance
    #
    # @param [ActionController::Parameters, Hash] params
    # @param [Blacklight::Configuration]          config
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#initialize
    #
    def initialize(params, config)
      @params = Blacklight::SearchStateExt.new(params, config).to_h
      @config = config
    end

    # Extracts advanced-type keyword query elements from query params,
    # returns as a hash of field => query.
    #
    # @return [Hash{Symbol=>String}]
    #
    # @see self#keyword_op
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#keyword_queries
    #
    def keyword_queries
      @keyword_queries ||=
        if @params[:search_field] == config.advanced_search[:url_key]
          config.search_fields.keys.map { |key|
            query = @params[key].presence
            [key, query] if query
          }.compact.to_h
        else
          {}
        end
    end

    # Extracts advanced-type filters from query params,
    # returned as a hash of field => [array of values]
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see BlacklightAdvancedSearch::QueryParser#filters
    #
    def filters
      @filters ||= @params[:f_inclusive]&.deep_dup || {}
    end

  end

end

__loading_end(__FILE__)
