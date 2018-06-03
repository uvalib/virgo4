# lib/ext/ebsco-eds/search_criteria_override.rb

__loading_begin(__FILE__)

require_relative 'eds_override'

# =============================================================================
# :section: Inject methods into EBSCO::EDS::SearchCriteria
# =============================================================================

override EBSCO::EDS::SearchCriteria do

  # ===========================================================================
  # :section: Replacement methods
  # ===========================================================================

  public

  # Override initializer to handle translating facets and for :f_inclusive
  # facets.
  #
  # @param [Hash]             options
  # @param [EBSCO::EDS::Info] info
  #
  # This method replaces:
  # @see EBSCO::EDS::SearchCriteria#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  # Although this accommodates both "inclusive-or" and "exclusive-or" facets,
  # not all combinations will work as expected.  However, this does not appear
  # to be a limitation of the EBSCO EDS gem; the server does not seem to handle
  # these combinations properly.
  #
  # For example:
  #
  #   ?...&f_inclusive[
  #
  def initialize(options, info)

    @Queries      = []
    @FacetFilters = []
    @Limiters     = []

    filter_id = 0

    # Blacklight year range slider input.
    #
    # 'range' => { 'pub_year_tisim' => { 'begin' => '1970', 'end' => '1980'} }
    #
    year = options.delete('range')&.dig('pub_year_tisim')
    if year.present?
      start_year = year['begin'].presence
      end_year   = year['end'].presence
      range = (start_year || end_year) && "#{start_year}-01/#{end_year}-01"
      @Limiters << { Id: 'DT1', Values: [range] } if range.present?
    end

    # Analyze Blacklight Advanced Search field, if present.
    # NOTE: the "search_field=advanced" case is not handled directly;
    # instead, individual search field queries are handled in the "else" clause
    # of the case statement below.
    search_field = options.delete('search_field')
    field_code   = get_field_code(search_field)

    # Blacklight Advanced Search logical operator.
    logical_op = options.delete('op').to_s.upcase
    logical_op = nil unless %w(AND OR).include?(logical_op)

    # Process all other parameters.
    #
    options.each do |key, value|

      case key

        # =====================================================================
        # Query
        # =====================================================================

        when 'q', 'query'
          value = value.to_s.squish
          if value.include?('_query_:')
            # Solr dismax syntax (from Blacklight Advanced Search).
            queries, search_mode = parse_query(value)
            @SearchMode = search_mode if search_mode
            @Queries += queries
          elsif value.include?('{!')
            # Search field query (modified by Blacklight Advanced Search).
            value = value.sub(/^{!qf=([^}]*)}/, '')
            fc    = get_field_code($1) || field_code
            query = { Term: value }
            query[:FieldCode]       = fc         if fc
            query[:BooleanOperator] = logical_op if logical_op
            @Queries << query
          else
            # Plain query.
            value = '*' if value.blank?
            query = { Term: value }
            query[:FieldCode]       = field_code if field_code
            query[:BooleanOperator] = logical_op if logical_op
            @Queries << query
          end

        # =====================================================================
        # Mode
        # =====================================================================

        when 'mode'
          available = info.available_search_mode_types
          value     = value.to_s.downcase
          @SearchMode = (value if available.include?(value))

        # =====================================================================
        # Sort
        # =====================================================================

        when 'sort'
          value = value.to_s.downcase
          @Sort = (value if info.available_sorts(value).present?)
          @Sort ||=
            case value
              when 'newest', 'pub_date_sort desc' then 'date'
              when 'oldest', 'pub_date_sort asc'  then 'date2'
              when 'score desc'                   then 'relevance'
            end

        # =====================================================================
        # Publication ID
        # =====================================================================

        when 'publication_id'
          @PublicationId = value.to_s

        # =====================================================================
        # Auto suggest & correct
        # =====================================================================

        when 'auto_suggest'
          @AutoSuggest = value ? 'y' : 'n'

        when 'auto_correct'
          @AutoCorrect = value ? 'y' : 'n'

        # =====================================================================
        # Expanders
        # =====================================================================

        when 'expanders'
          available = info.available_expander_ids
          expanders =
            Array.wrap(value)
              .map    { |item| item.to_s.downcase }
              .select { |item| available.include?(item) }
          if expanders.present?
            @Expanders ||= []
            @Expanders += expanders
          end

        # =====================================================================
        # Related content
        # =====================================================================

        when 'related_content'
          available = info.available_related_content_types
          related_content =
            Array.wrap(value)
              .map    { |item| item.to_s.downcase }
              .select { |item| available.include?(item) }
          if related_content.present?
            @RelatedContent ||= []
            @RelatedContent += related_content
          end

        # =====================================================================
        # Facets
        # =====================================================================

        when 'include_facets'
          @IncludeFacets = value ? 'y' : 'n'

        when 'facet_filters'
          @FacetFilters += Array.wrap(value).reject(&:blank?)

        # =====================================================================
        # Solr filter query (Blacklight Advanced Search)
        #
        # === Examples
        # '{!term f=eds_publication_facet}New York Times'
        # '{!term f=eds_publication_year_facet tag=eds_publication_year_facet_single}2013'
        # 'eds_content_provider_facet:("ERIC" OR  "JSTOR Journals")'
        # =====================================================================

        when 'fq'
          @FacetFilters +=
            Array.wrap(value).flat_map { |filter_query|
              facet_type = facet_name = facet_values = nil
              case filter_query
                when /^{!terms? (f[^=]*)=([^}]+)}(.+)$/
                  facet_type, facet_name, facet_values = $1, $2, $3
                  facet_type = facet_type.to_s
                  facet_name = facet_name.to_s.sub(/ +tag=.*$/, '')
                  facet_values = facet_values.to_s.split(',')
                when /^([^:]+):\((.*)\)$/
                  facet_name, facet_values = $1, $2
                  facet_name = facet_name.to_s
                  if (parts = facet_values.to_s.split(/ +OR +/)).size > 1
                    facet_type = 'f_inclusive'
                  else
                    parts = facet_values.to_s.split(/ +AND +/)
                    facet_type = 'f'
                  end
                  facet_values =
                    parts.map { |v| v.sub(/^\\?"+(.*)\\?"+$/, '\1') }
              end
              next unless facet_values.present?
              if facet_name == 'eds_search_limiters_facet'
                update_search_limiters(facet_values, info, logical_op)
              elsif facet_name == 'eds_publication_year_range_facet'
                update_date_range_limiter(facet_values, info)
              elsif (ef = EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET[facet_name])
                case facet_type
                  when 'f_inclusive'
                    filter_id += 1
                    facet_filter(filter_id, ef, facet_values)
                  when 'f'
                    facet_values.map do |facet_value|
                      filter_id += 1
                      facet_filter(filter_id, ef, facet_value)
                    end
                end
              end
            }.compact

        # =====================================================================
        # Solr "inclusive-or" facets for Blacklight Advanced Search
        # =====================================================================

        when 'f_inclusive'
          @FacetFilters +=
            EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET.map { |sf, ef|
              facet_values = Array.wrap(value[sf]).reject(&:blank?)
              next unless facet_values.present?
              filter_id += 1
              facet_filter(filter_id, ef, facet_values)
            }.compact

        # =====================================================================
        # Solr "exclusive-or" facets and limiters
        # =====================================================================

        when 'f'
          @FacetFilters +=
            EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET.flat_map { |sf, ef|
              facet_values = Array.wrap(value[sf]).reject(&:blank?)
              facet_values.map { |facet_value|
                filter_id += 1
                facet_filter(filter_id, ef, facet_value)
              }
            }

          values = Array.wrap(value['eds_search_limiters_facet'])
          update_search_limiters(values, info, logical_op) if values.present?

          values = Array.wrap(value['eds_publication_year_range_facet'])
          update_date_range_limiter(values, info) if values.present?

        # =====================================================================
        # Limiters
        # =====================================================================

        when 'limiters'
          available = info.available_limiter_ids
          @Limiters +=
            Array.wrap(value).map { |item|
              parts = item.to_s.split(':', 2)
              l_key = parts.shift.upcase
              next unless available.include?(l_key)
              # If multi-value, add the values if they're available.
              # Do nothing if none of the values are available.
              # TODO: make case insensitive?
              limiter = parts.join(':')
              if info.available_limiters(l_key)['Type'] == 'multiselectvalue'
                l_avail = info.available_limiter_values(l_key)
                limiter = limiter.split(',').select { |v| l_avail.include?(v) }
              end
              limiter = Array.wrap(limiter).compact
              { Id: l_key, Values: limiter } if limiter.present?
            }.compact

        # =====================================================================
        # Blacklight Advanced Search query
        # =====================================================================

        else
          if value.present? && (fc = get_field_code(key))
            query = { FieldCode: fc, Term: value.to_s }
            query[:BooleanOperator] = logical_op if logical_op
            @Queries << query
          else
            Rails.logger.debug {
              "EDS SearchCriteria: ignoring param #{key} = #{value.inspect}"
            }
          end

      end

    end

    # Remove null search if it is not needed because other search terms were
    # introduced.
    @Queries << { Term: '*', BooleanOperator: logical_op } if logical_op
    @Queries.uniq!
    non_null = @Queries.reject { |q| q[:Term] == '*' }
    @Queries = non_null if non_null.present?

    # Because there is some inconsistent usage of Symbol versus String for hash
    # keys, ensure that all hashes generated here can accomodate that.
    normalize!(@Queries)
    normalize!(@FacetFilters)
    normalize!(@Limiters)

    # Defaults.
    @AutoCorrect    ||= info.default_auto_correct
    @AutoSuggest    ||= info.default_auto_suggest
    @Expanders      ||= info.default_expander_ids
    @RelatedContent ||= info.default_related_content_types
    @SearchMode     ||= info.default_search_mode
    @IncludeFacets  ||= 'y'
    @Sort           ||= 'relevance'

  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  private

  # parse_query
  #
  # @param [String] q
  #
  # @return [Array<(Array<Hash>,String)]
  #
  # == Implementation Notes
  # This makes use of the fact that Blacklight Advanced Search has already
  # parsed the original query into a tree so parenthesis nesting and logical
  # operators (where the exist) are preserved.  This method simply transforms
  # '_query:"{!dismax...}..."' terms into a form that can be used by EDS.
  #
  # Parentheses will have been removed from the input search terms, so any
  # parentheses in found in *q* represent grouping of logical terms.
  #
  # TODO: still doesn't handle parentheses properly.
  #
  def parse_query(q)
    queries = []
    count = -1
    mode = nil
    outline =
      q.gsub(/_query_:"{!dismax *(qf=\w+)? *(mm=1)?}([^"]+)" *(AND|OR)?/) do
        mode =
          case $4
            when 'OR'  then 'any'
            when 'AND' then 'all'
          end
        query = { Term: $3.to_s.squish }
        query[:BooleanOperator] = 'OR' if $2 == 'mm=1'
        search_field = $1.to_s.strip.sub!(/^qf=/, '')
        field_code   = get_field_code(search_field)
        query[:FieldCode] = field_code if field_code.present?
        queries << query
        "#{count+=1}"
      end
    mode ||= outline.include?('OR') ? 'any' : 'all'
    return queries, mode
  end

  # Create an entry for @FacetFilters.
  #
  # @param [Integer]               filter_id
  # @param [String]                ebsco_facet
  # @param [String, Array<String>] values
  #
  # @return [Hash]
  #
  def facet_filter(filter_id, ebsco_facet, values)
    values = Array.wrap(values)
    values = values.map { |value| { Id: ebsco_facet, Value: value } }
    { FilterId: filter_id, FacetValues: values }
  end

  # Only handle 'select' limiters (ones with values of 'y' or 'n').
  #
  # @param [String, Array<String>] values
  # @param [EBSCO::EDS::Info]      info
  #
  # @return [nil]
  #
  def update_search_limiters(values, info, logical_op = nil)
    logical_op ||= 'AND'
    limiters = info.available_limiters
    @Limiters +=
      Array.wrap(values).map { |value|
        limiter =
          limiters.find do |l|
            (l['Type'] == 'select') && [l['Id'], l['Label']].include?(value)
          end
        next unless limiter
        { Id: limiter['Id'], Values: ['y'] }.tap { |result|
          result[:BooleanOperator] = logical_op if logical_op
        }
      }.compact
    nil
  end

  # Date limiters.
  #
  # @param [String, Array<String>] values
  # @param [EBSCO::EDS::Info]      info
  #
  # @return [nil]
  #
  def update_date_range_limiter(values, info)
    yy = Date.today.year
    mm = Date.today.month
    @Limiters +=
      Array.wrap(values).map { |value|
        range =
          case value.to_s.capitalize
            when 'This year'     then "#{yy}-01/#{yy}-#{mm}"
            when 'Last 3 years'  then "#{yy-3}-#{mm}/#{yy}-#{mm}"
            when 'Last 10 years' then "#{yy-10}-#{mm}/#{yy}-#{mm}"
            when 'Last 50 years' then "#{yy-50}-#{mm}/#{yy}-#{mm}"
            when 'More than 50 years ago' then "0000-01/#{yy-50}-12"
          end
        { Id: 'DT1', Values: [range] } if range.present?
      }.compact
    nil
  end

  # Translate a Solr search field to an EBSCO field code.
  #
  # @param [String] search_field
  #
  # @return [String, nil]
  #
  def get_field_code(search_field)
    search_field = search_field.to_s.squish
    if search_field =~ /^[A-Z]{2}$/
      search_field
    else
      search_field = search_field.tr(' ', '_').underscore
      EBSCO::EDS::SOLR_SEARCH_TO_EBSCO_FIELD_CODE[search_field]
    end
  end

  # Convert hashes to ActiveSupport::HashWithIndifferentAccess.
  #
  # @param [Array<Hash>] array        Array of hashes to modify.
  #
  # @return [Array<ActiveSupport::HashWithIndifferentAccess>]
  #
  def normalize!(array)
    array.map! do |entry|
      entry.is_a?(Hash) ? entry.with_indifferent_access : entry
    end
  end

end

__loading_end(__FILE__)
