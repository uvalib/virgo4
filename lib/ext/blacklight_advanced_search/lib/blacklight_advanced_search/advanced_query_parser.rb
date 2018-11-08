# lib/ext/blacklight_advanced_search/lib/blacklight_advanced_search/advanced_query_parser.rb
#
# Inject BlacklightAdvancedSearch::QueryParser extensions and replacement
# methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search/advanced_query_parser'

# Override BlacklightAdvancedSearch definitions.
#
# @see BlacklightAdvancedSearch::QueryParser
#
module BlacklightAdvancedSearch::QueryParserExt

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::QueryParser overrides
  # ===========================================================================

  public

  # Initialize a new instance
  #
  # @param [Hash]                      params
  # @param [Blacklight::Configuration] config
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::QueryParser#initialize
  #
  def initialize(params, config)
    @params = Blacklight::Lens::SearchState.new(params, config).to_h
    @config = config
  end

  # extracts advanced-type keyword query elements from query params,
  # returns as a kash of field => query.
  # see also keyword_op
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::QueryParser#keyword_queries
  #
  def keyword_queries
    @keyword_queries ||=
      if @params[:search_field] == config.advanced_search.url_key
        keys = config.search_fields.keys.map(&:to_sym)
        @params.slice(*keys).select { |_, v| v.present? }
      else
        {}
      end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Gives a mapping of all filters that behave as exclusive ("and"-ed)
  # selections, including singleton inclusive facet selections.
  #
  # @return [Hash{Symbol=>Array<String>}]
  #
  # Compare with:
  # @see BlacklightAdvancedSearch::QueryParser#filters
  #
  def exclusive_filters
    @exclusive_filters ||=
      {}.tap do |result|
        # First any normal (AND'ed) facet selections.
        (@params[:f] || {}).each_pair do |field, value_array|
          result[field] = value_array.dup
        end
        # Next any singleton advanced (OR'ed) facet selections.
        (@params[:f_inclusive] || {}).each_pair do |field, value_array|
          next unless value_array.size == 1
          result[field] ||= []
          result[field] << value_array.first
        end
      end
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override BlacklightAdvancedSearch::QueryParser =>
         BlacklightAdvancedSearch::QueryParserExt

__loading_end(__FILE__)
