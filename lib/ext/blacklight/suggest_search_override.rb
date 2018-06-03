# lib/ext/blacklight/suggest_search_override.rb
#
# Temporary override of SuggestSearch behavior to cope with the fact that the
# current Solr version is not set up for it.
#
# TODO: Remove this file when Solr has the proper suggest handler.

__loading_begin(__FILE__)

require 'blacklight/suggest_search'

SUGGEST_SEARCH_OVERRIDE_MAPPING = {
  title: %i(
    main_title_display
    title_display
    subtitle_display
    alternate_title_display
    series_title_display
    uniform_title_facet
    linked_title_display
  ),
  author: %i(
    author_display
    linked_author_display
    responsibility_statement_display
    linked_responsibility_statement_display
  ),
  journal:     %i(
    journal_title_text
    journal_addnl_title_text
  ),
  subject:     %i(subject_facet subject_era_facet subject_genre_facet),
  keyword:     %i(keywords_display),
  isbn:        %i(isbn_display),
  issn:        %i(issn_display),
  call_number: %i(call_number_display),
  published:   %i(published_display),
}.stringify_keys.freeze

# =============================================================================
# :section: Inject Blacklight::SuggestSearch replacement methods
# =============================================================================

override Blacklight::SuggestSearch do

  # Initialize a Blacklight::SuggestSearch instance.
  #
  # @param [ActionController::Parameters, Hash] params
  # @param [Blacklight::AbstractRepository]     repository
  #
  # This method replaces:
  # @see Blacklight::SuggestSearch#initialize
  #
  # TODO: Remove this override when Solr has the proper suggest handler.
  #
  def initialize(params, repository)
    super
    sf = params[:search_field].to_s.presence
    sf = nil if sf && %w(advanced all_fields).include?(sf)
    @request_params[:search_field] = sf if sf
    display_fields = SUGGEST_SEARCH_OVERRIDE_MAPPING[sf].presence
    display_fields ||= SUGGEST_SEARCH_OVERRIDE_MAPPING.values.flatten
    @request_params[:fl]    = [:score, *display_fields].compact.uniq.join(',')
    @request_params[:facet] = 'false'
    @request_params[:qt]    = 'dismax' if sf
    @request_params[:rows]  = 25
  end

  # Just use the normal Solr handler for now.
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::SuggestSearch#suggest_handler_path
  #
  # TODO: Remove this override when Solr has the proper suggest handler.
  #
  def suggest_handler_path
    'select'
  end

end

# =============================================================================
# :section: Inject Blacklight::Suggest::Response replacement methods
# =============================================================================

override Blacklight::Suggest::Response do

  # Extracts suggested terms from the suggester response.
  #
  # This is a modified version of:
  # @see Blacklight::Eds::Suggest::ResponseEds#suggestions
  #
  # @return [Array<Hash{String=>String}>]
  #
  # @see RSolr::HashWithResponse
  #
  # This method replaces:
  # @see Blacklight::Suggest::Response#suggestions
  #
  # TODO: Remove this override when Solr has the proper suggest handler.
  #
  def suggestions
    query =
      request_params[:q].to_s.squish.downcase
        .sub(/^[^a-z0-9_]+/, '').sub(/[^a-z0-9_]+$/, '')
        .split(' ')
    docs = response.dig('response', 'docs') || []
    docs
      .map { |doc|
        # To prepare for sorting by descending order of usefulness, transform
        # each *doc* into an array with these elements:
        # [0] all_score - terms with all matches to the top
        # [1] any_score - terms with most matches to the top
        # [2] score     - tie-breaker sort by descending relevance
        # [3..-1]       - fields with terms
        terms = doc.except('score').values.flatten.map(&:downcase)
        any = query.count { |qt| terms.any? { |term| term.include?(qt) } }
        next if any.zero?
        all = query.count { |qt| terms.all? { |term| term.include?(qt) } }
        terms.unshift(-doc['score'].to_f)
        terms.unshift(query.size - any)
        terms.unshift(query.size - all)
      }
      .compact
      .sort
      .map { |terms| terms.shift(3); terms } # Remove non-search-terms.
      .flatten
      .uniq
      .select { |term| query.any? { |query_term| term.include?(query_term) } }
      .sort_by { |term| query.size - query.count { |qt| term.include?(qt) } }
      .map { |term| { 'term' => term, 'weight' => 1, 'payload' => '' } }
  end

end

__loading_end(__FILE__)
