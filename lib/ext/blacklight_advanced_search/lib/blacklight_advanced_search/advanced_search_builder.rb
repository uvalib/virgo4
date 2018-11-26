# lib/ext/blacklight_advanced_search/lib/blacklight_advanced_search/advanced_search_builder.rb
#
# Inject BlacklightAdvancedSearch::AdvancedSearchBuilder extensions and
# replacement methods.

__loading_begin(__FILE__)

require 'blacklight_advanced_search/advanced_search_builder'

# Override BlacklightAdvancedSearch definitions.
#
# @see BlacklightAdvancedSearch::AdvancedSearchBuilder
#
module BlacklightAdvancedSearch::AdvancedSearchBuilderExt

  include Blacklight::Lens::SearchFields

  # ===========================================================================
  # :section: BlacklightAdvancedSearch::AdvancedSearchBuilder overrides
  # ===========================================================================

  public

  # This method can be included in the SearchBuilder to have us parse an
  # ordinary entered :q for AND/OR/NOT and produce appropriate Solr query.
  #
  # Note: For syntactically invalid input, we'll just skip the adv parse and
  # send it straight to solr same as if advanced_parse_q were not being used.
  #
  # @param [Hash] solr_parameters
  #
  # @return [void]
  #
  # This method overrides:
  # @see BlacklightAdvancedSearch::AdvancedSearchBuilder#add_advanced_parse_q_to_solr
  #
  # == Implementation Notes
  # This method is overridden for Blacklight 7 because it relies upon a method
  # removed from Blacklight::SearchFields.
  #
  def add_advanced_parse_q_to_solr(solr_parameters)
    q = blacklight_params[:q]
    return unless q.present? && q.respond_to?(:to_str)

    # If the individual field has advanced_parse_q suppressed, punt.
    field     = blacklight_params[:search_field]
    field_def = search_field_def_for_key(field) || default_search_field
    return if field_def[:advanced_parse].is_a?(FalseClass)

    solr_direct_params = field_def[:solr_parameters] || {}
    solr_local_params  = field_def[:solr_local_parameters] || {}

    # See if we can parse it, if we can't, we're going to give up and just
    # allow basic search, perhaps with a warning.
    qp = blacklight_config.advanced_search[:query_parser]
    node = ParsingNesting::Tree.parse(q, qp)
    adv_search_params = node.to_single_query_params(solr_local_params)
    BlacklightAdvancedSearch.deep_merge(solr_parameters, solr_direct_params)
    BlacklightAdvancedSearch.deep_merge(solr_parameters, adv_search_params)

  rescue *PARSLET_FAILED_EXCEPTIONS_COPY
    # Do nothing, don't merge our input in, keep basic search.
    # Optional TODO, display error message in flash here, but hard to
    # display a good one.
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Internal copy of:
  # BlacklightAdvancedSearch::AdvancedSearchBuilder#PARSLET_FAILED_EXCEPTIONS
  PARSLET_FAILED_EXCEPTIONS_COPY =
    if defined?(Parslet::UnconsumedInput)
      [Parslet::UnconsumedInput]
    else
      [Parslet::ParseFailed]
    end.freeze

end

# =============================================================================
# Override gem definitions
# =============================================================================

override BlacklightAdvancedSearch::AdvancedSearchBuilder =>
         BlacklightAdvancedSearch::AdvancedSearchBuilderExt

__loading_end(__FILE__)
