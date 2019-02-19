# lib/ext/ebsco-eds/lib/ebsco/eds/results.rb
#
# Inject EBSCO::EDS::Results extensions and replacement methods.

__loading_begin(__FILE__)

# Override EBSCO::EDS definitions.
#
# @see EBSCO::EDS::Results
#
module EBSCO::EDS::ResultsExt

  TITLEIZE_FACETS = %w(
    Language
    Journal
    SubjectEDS
    SubjectGeographic
    Publisher
  ).freeze

  # A number of potential search limiters are supplied by the EBSCO response
  # but only "peer reviewed" is known to be valid for our EBSCO profile.
  #
  # This table documents that fact while allowing for the possibility that
  # other limiter(s) may be determined to be useful in the future.
  #
  # @type [Hash{String=>Boolean}]
  #
  # @see self#solr_search_limiters
  #
  SEARCH_LIMITERS = {
    FR:  false, # "References Available"
    FT:  false, # "Full Text"
    FT1: false, # "Available in Library Collection"
    RV:  true,  # "Scholarly (Peer Reviewed) Journals"
  }.stringify_keys.freeze

  # The list of search limiters that will be honored by the application.
  #
  # @type [Array<String>]
  #
  ACTIVE_SEARCH_LIMITERS =
    SEARCH_LIMITERS.map { |id, active| id if active }.compact.freeze

  # ===========================================================================
  # :section: EBSCO::EDS::Results overrides
  # ===========================================================================

  public

  # Creates search results from the \EDS API search response. It includes
  # information about the results and a list of Record items.
  #
  # @param [Hash]                      search_results
  # @param [EBSCO::EDS::Configuration] eds_config
  # @param [Hash]                      limiters
  # @param [Hash]                      opt
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#initialize
  #
  def initialize(search_results, eds_config = nil, limiters = nil, opt = nil)

    eds_config ||= {}
    @results     = search_results || {}
    @limiters    = limiters || []
    @raw_options = opt || {}

    result               = @results['SearchResult'] || {}
    data_records         = result.dig('Data', 'Records') || []
    statistics           = result['Statistics'] || {}
    related_content      = result['RelatedContent'] || {}
    related_records      = related_content['RelatedRecords'] || []
    related_publications = related_content['RelatedPublications'] || []

    @did_you_mean     = result['AutoSuggestedTerms']&.first
    @auto_corrections = result['AutoCorrectedTerms']&.first

    @stat_total_hits  = statistics['TotalHits'].to_i
    @stat_total_time  = statistics['TotalSearchTime'].to_i

    # Convert all results to a list of records.
    @records =
      data_records.map { |record|
        EBSCO::EDS::Record.new(record, eds_config)
        # # Records hidden in guest mode.
        # if record['Header']['AccessLevel']
        #   if record['Header']['AccessLevel'].to_i > 1
        #     EBSCO::EDS::Record.new(record)
        #   else
        #     EBSCO::EDS::Record.new(record)
        #   end
        # else
        #   EBSCO::EDS::Record.new(record)
        # end
      }.compact

    # Create a special list of research starter records.
    @research_starters =
      related_records.flat_map { |item|
        next unless item['Type'] == 'rs'
        recs = item['Records'] || []
        recs.map { |rec| EBSCO::EDS::Record.new(rec, eds_config) }
      }.compact

    # Create a special list of exact match publications.
    @publication_match =
      related_publications.flat_map { |item|
        next unless item['Type'] == 'emp'
        recs = item['PublicationRecords'] || []
        recs.map { |rec| EBSCO::EDS::Record.new(rec, eds_config) }
      }.compact

    # Titleize facets?
    @titleize_facets = TITLEIZE_FACETS
    @titleize_facets_on =
      if (env_value = ENV['EDS_TITLEIZE_FACETS']).present?
        %w(y yes true).include?(env_value.to_s.downcase)
      else
        eds_config[:titleize_facets]
      end

    # Facet pagination properties.
    init_facet_pagination(@raw_options)

  end

  # Convert to the Solr search response format.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#to_solr
  #
  def to_solr

    records   = @records || []
    solr_docs = records.map(&:to_attr_hash)

    solr_start = solr_docs.first&.dig('eds_result_id')
    solr_start = solr_start ? (solr_start.to_i - 1) : 0

    # Solr execution parameters to be reported in the response.
    params = {
      q:     search_terms.join(' '),
      wt:    'ruby',
      start: solr_start,
      rows:  results_per_page,
      facet: true
    }

    # General facet property params.
    fparams = {
      'facet.field'  => (@facet_field_array || @facet_field),
      'facet.sort'   => @facet_sort,
      'facet.limit'  => @facet_limit,
      'facet.offset' => @facet_offset,
      'facet.prefix' => @facet_prefix,
    }
    params.merge!(fparams)

    # Facet-specific facet property params.
    ffparams = @raw_options.select { |k, _| k =~ /^f\.[^.]+\.facet\.[^.]+$/ }
    params.merge!(ffparams)
    params.delete_if { |_, v| v.blank? }

    # Suggestions and corrections.
    spellcheck = solr_spellcheck.presence

    # Search match highlighting.
    highlighting =
      if retrieval_criteria['Highlight'] == 'y'
        records.map { |record|
          db_an = record.eds_database_id + '__' + record.eds_accession_number
          hl_title = record.eds_title.gsub(%r{<(/?)highlight>}, '<\1em>')
          [db_an, { 'title_display' => [hl_title] }]
        }.to_h.presence
      end

    # Research starters.
    research_starters = @research_starters.map(&:to_attr_hash).presence

    # Publication matches.
    publication_matches = @publication_match.map(&:to_attr_hash).presence

    # Fill in the Solr response, transforming EDS facet result arrays into
    # flattened value/count arrays.  Facet pagination parameters will be
    # applied to the facet associated with @eds_facet.
    res = {
      responseHeader: {
        status: 0,
        QTime:  @stat_total_time,
        params: params
      },
      response: {
        numFound: @stat_total_hits,
        start:    solr_start,
        docs:     solr_docs
      },
      date_range: date_range,
      facet_counts: {
        facet_fields: {
          eds_search_limiters_facet:        solr_search_limiters,
          eds_publication_type_facet:       solr_facets('SourceType'),
          eds_language_facet:               solr_facets('Language'),
          eds_subject_topic_facet:          solr_facets('SubjectEDS'),
          eds_publication_year_facet:       solr_facets('PublicationYear'),
          eds_publication_year_range_facet: solr_pub_date_facets,
          eds_publisher_facet:              solr_facets('Publisher'),
          eds_journal_facet:                solr_facets('Journal'),
          eds_subjects_geographic_facet:    solr_facets('SubjectGeographic'),
          eds_category_facet:               solr_facets('Category'),
          eds_content_provider_facet:       solr_facets('ContentProvider'),
          eds_library_location_facet:       solr_facets('LocationLibrary'),
          eds_library_collection_facet:     solr_facets('CollectionLibrary'),
          eds_author_university_facet:      solr_facets('AuthorUniversity'),
          pub_year_tisim:                   solr_facets('PublicationYear')
        }
      }
    }
    res.merge!(spellcheck)                               if spellcheck
    res.merge!(highlighting:        highlighting)        if highlighting
    res.merge!(research_starters:   research_starters)   if research_starters
    res.merge!(publication_matches: publication_matches) if publication_matches
    res.deep_stringify_keys!
  end

  # Translate limiters found in calls to Info endpoint into solr facet fields
  # if they are turned on.
  #
  # This override only makes use of the ones enabled in self#SEARCH_LIMITERS.
  #
  # @return [Array<Hash>]
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#solr_search_limiters
  #
  def solr_search_limiters
    return [] if stat_total_hits.zero? || @limiters.blank?
    @limiters.flat_map { |item|
      [item['Label'], ''] if ACTIVE_SEARCH_LIMITERS.include?(item['Id'])
    }.compact
  end

  # Generate Solr facet values and counts, applying sort, prefix and offset.
  #
  # If *facet_id* matches @eds_facet then facet pagination parameters
  # ('facet.sort', 'facet.prefix', 'facet.offset') are applied so that the
  # returned Solr record has
  #
  # @param [String] facet_id          EDS facet name.
  #
  # @return [Array<String>]           Alternating values and counts.
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#solr_facets
  #
  def solr_facets(facet_id = 'all')

    # Convert facet pagination parameters into a useful form, ensuring that
    # non-applicable parameters are *nil*.  (Facets arrive in the order
    # specified by `@facet_sort == 'count'` so no sort action is required in
    # this case).
    sort   = (@facet_sort if @facet_sort == 'index')
    prefix = @facet_prefix.to_s.upcase.presence
    offset = (@facet_offset if @facet_offset&.nonzero?)

    # Extract facet element array from the results.
    tmp_results =
      if facet_id == 'SourceType'
        temp_format_facet_results&.results
      elsif facet_id == 'ContentProvider'
        temp_content_provider_facet_results&.results
      end
    available_facets =
      (tmp_results || @results).dig('SearchResult', 'AvailableFacets') || []

    # Process the facet elements into an flattened array of value/count pairs
    # subject to the actions specified through the facet pagination parameters.
    available_facets.map { |available_facet|

      af_id     = available_facet['Id']
      af_values = available_facet['AvailableFacetValues']
      next unless [af_id, 'all'].include?(facet_id) && af_values.present?

      # Convert facet elements to value/count pairs with the value titleized
      # if applicable.
      af_values = af_values.map { |entry| [entry['Value'], entry['Count']] }
      if @titleize_facets_on && @titleize_facets.include?(af_id)
        af_values.map! { |v, c| [EBSCO::EDS::Titleize.new.titleize(v), c] }
      end

      # If this is the facet of interest (e.g. for paginating the facet
      # presented through the Blacklight facet modal dialog), apply facet
      # action parameters in the correct order to transform the resulting
      # array of value/count pairs.
      if af_id == @eds_facet
        af_values.sort! if sort
        if prefix
          af_values =
            af_values
              .drop_while { |v, _| v.upcase <  prefix }
              .take_while { |v, _| v[0, prefix.size].upcase == prefix }
        end
        af_values = af_values.drop(offset) if offset
      end
      af_values

    }.flatten.compact

  end

  # Returns a hash of the date range available for the search.
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#date_range
  #
  # @example
  # { mindate: '1501-01',
  #   maxdate: '2018-04',
  #   minyear: '1501',
  #   maxyear: '2018' }
  #
  def date_range
    dr = @results.dig('SearchResult', 'AvailableCriteria', 'DateRange') || {}
    mindate = dr['MinDate'].to_s
    maxdate = dr['MaxDate'].to_s
    minyear = mindate[0..3]
    maxyear = maxdate[0..3]

    # Cap max_date/max_year to current year + 1 (to filter any erroneous
    # database metadata).
    current_year = Time.new.year
    if maxyear.to_i > current_year
      maxyear = (current_year + 1).to_s.force_encoding('UTF-8')
      maxdate = maxyear + '-01'
    end

    { mindate: mindate, maxdate: maxdate, minyear: minyear, maxyear: maxyear }
  end

  # Returns a simple list of the search terms used. Boolean operators are not
  # indicated.
  #
  # This method overrides:
  # @see EBSCO::EDS::Results#search_terms
  #
  # == Example
  #   ["earthquakes", "california"]
  #
  def search_terms
    @search_terms ||=
      begin
        queries =
          @results.dig(
            'SearchRequest',
            'SearchCriteriaWithActions',
            'QueriesWithAction'
          ) || []
        queries.flat_map { |query| query['Query']['Term'].split }
      end
  end

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  public

  # Total number of results found.
  #
  # @return [Integer]
  #
  attr_accessor :stat_total_hits

  # Time it took to complete the search in milliseconds.
  #
  # @return [Integer]
  #
  attr_accessor :stat_total_time

  # Provides alternative search terms to correct spelling, etc.
  #
  # == Example
  #   results = session.simple_search('earthquak')
  #   results.did_you_mean
  #   => "earthquake"
  #
  # @return [String, nil]
  #
  attr_accessor :did_you_mean

  # auto_corrections
  #
  # @return [String, nil]
  #
  attr_accessor :auto_corrections

  # If present, this is the EDS facet of interest.
  #
  # @return [String, nil]
  #
  attr_accessor :facet_field

  # The sort order of facet values to return via #solr_facets.
  #
  # @return [String, nil]
  #
  attr_accessor :facet_sort

  # The "page" of facet values to return via #solr_facets.
  #
  # @return [String, nil]
  #
  attr_accessor :facet_page

  # The size of a facet value "page" returned via #solr_facets.
  #
  # @return [String, nil]
  #
  attr_accessor :facet_per_page

  # ===========================================================================
  # :section: Added methods
  # ===========================================================================

  protected

  # Initialize facet pagination values.
  #
  # @param [Hash] opt                 Default: `@raw_options`.
  #
  # @return [void]
  #
  def init_facet_pagination(opt = @raw_options)

    case (@facet_field = opt['facet.field'])
      when Array
        @facet_field_array = @facet_field
        @facet_field       = nil
      when /^.*}([^}]+)$/
        @facet_field_array = [@facet_field]
        @facet_field       = $1
      else
        @facet_field_array = nil
        @facet_field       = @facet_field.presence
    end

    ff = @facet_field
    @eds_facet = (EBSCO::EDS::SOLR_FACET_TO_EBSCO_FACET[ff] if ff)

    # The returned values of the indicated facet should be sorted:
    #   'count' - in descending order of hit count
    #   'index' - in collation order of the facet value
    @facet_sort =
      (opt["f.#{ff}.facet.sort"] if ff) ||
        opt['facet.sort'] ||
        (opt['sort'] if ff)

    # Only return values of the indicated facet beginning with the given string
    # ('index' sort is required).
    @facet_prefix = (opt["f.#{ff}.facet.prefix"] if ff) || opt['facet.prefix']
    @facet_sort = 'index' if @facet_prefix

    # The returned values of the indicated facet should begin at the given
    # index offset.
    @facet_offset =
      (opt["f.#{ff}.facet.offset"] if ff) ||
        opt['facet.offset'] ||
        opt['offset']

    # The only this many values from the indicated facet should be returned.
    @facet_limit =
      (opt["f.#{ff}.facet.limit"] if ff) ||
        opt['facet.limit'] ||
        opt['limit'] ||
        (opt['rows'] if ff)

    # If 'facet.page' was supplied instead of 'facet.offset', calculate the
    # implied offset.
    @facet_page = opt['facet.page'] || (opt['page'] if ff)
    if @facet_page && !@facet_offset
      @facet_limit ||= 21
      @facet_offset = (@facet_page.to_i * @facet_limit.to_i) - 1
    end

    # Ensure that numeric values are converted to numbers.
    @facet_limit  &&= @facet_limit.to_i
    @facet_offset &&= @facet_offset.to_i

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override EBSCO::EDS::Results => EBSCO::EDS::ResultsExt

__loading_end(__FILE__)
