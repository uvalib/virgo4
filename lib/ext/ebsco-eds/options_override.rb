# lib/ext/ebsco-eds/options_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::Options
# =============================================================================

override EBSCO::EDS::Options do

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Override initializer to handle facet pagination.
  #
  # @param [Hash]             options
  # @param [EBSCO::EDS::Info] info
  #
  # This method replaces:
  # @see EBSCO::EDS::Options#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  def initialize(options, info)

    @SearchCriteria    = EBSCO::EDS::SearchCriteria.new(options, info)
    @RetrievalCriteria = EBSCO::EDS::RetrievalCriteria.new(options, info)

    # add DefaultOn=y Type=select limiters
    # info.available_limiters.each do |limiter|
    #   if (limiter['DefaultOn'] == 'n') && (limiter['Type'] == 'select')
    #     @Actions << "addLimiter(#{limiter['Id']}:y)"
    #   end
    # end

    actions = options['actions']
    add_actions(actions, info) if actions.present?

    # Solr: Need to add page actions whenever other actions are present since
    # the other actions will always reset the page to 1 even though a
    # @PageNumber is present in RetrievalCriteria.
    page = @RetrievalCriteria.PageNumber || 1
    add_actions("GoToPage(#{page})", info) unless page == 1

=begin
    # Add page default of 1.
    options['page'] ||= @RetrievalCriteria.PageNumber || 1
=end

    # Defaults
    @Comment ||= ''

  end

  # add_actions
  #
  # @param [Array, String]    actions
  # @param [EBSCO::EDS::Info] info      Currently unused.
  #
  # @return [void]
  #
  def add_actions(actions, info)
    @Actions ||= []
    @Actions += Array.wrap(actions)
    #@Actions += Array.wrap(actions).select { |it| is_valid_action(it, info) }
  end

  # Caution: experimental, not ready for production.
  #
  # @return [String]
  #
  # @example query-1=AND,volcano&sort=relevance&includefacets=y&searchmode=all&autosuggest=n&view=brief&resultsperpage=20&pagenumber=1&highlight=y
  #
  def to_query_string

    # SEARCH CRITERIA:
    query = @SearchCriteria.Queries&.first
    query &&=
      +''.tap do |q|
        #q << query[:BooleanOperator] || 'AND'
        #q << ',' << query[:FieldCode] << ':' if query[:FieldCode]
        q << query[:Term]
      end

    qs = {
      query:          query,
      searchmode:     @SearchCriteria.SearchMode,
      includefacets:  @SearchCriteria.IncludeFacets,
      sort:           @SearchCriteria.Sort,
      autosuggest:    @SearchCriteria.AutoSuggest,
      autocorrect:    @SearchCriteria.AutoCorrect,
      limiter:        @SearchCriteria.Limiters,
      expander:       @SearchCriteria.Expanders,
      relatedcontent: @SearchCriteria.RelatedContent,
      view:           @RetrievalCriteria.View,
      resultsperpage: @RetrievalCriteria.ResultsPerPage,
      pagenumber:     @RetrievalCriteria.PageNumber,
      highlight:      @RetrievalCriteria.Highlight,
    }.map { |key, value|
      next unless key.present? && value.present?
      value = value.join(',') if value.is_a?(Array)
      %Q(#{key}=#{value})
    }

    qs +=
      Array.wrap(@SearchCriteria.FacetFilters).map { |filter|
        id     = filter[:FilterId]
        entry  = filter[:FilterValues].first
        facet  = entry[:Id]
        values = Array.wrap(entry[:Value]).join(',')
        %Q(facetfilter=#{id},#{facet}:#{values})
      }

    qs += Array.wrap(@Actions).map { |action| %Q(action=#{action}) }

    '?' + qs.reject(&:blank?).join('&')

  end

end

__loading_end(__FILE__)
