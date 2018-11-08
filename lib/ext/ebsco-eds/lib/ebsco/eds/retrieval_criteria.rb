# lib/ext/ebsco-eds/lib/ebsco/eds/retrieval_criteria.rb
#
# Inject EBSCO::EDS::RetrievalCriteria extensions and replacement methods.

__loading_begin(__FILE__)

# Override EBSCO::EDS definitions.
#
# @see EBSCO::EDS::RetrievalCriteria
#
module EBSCO::EDS::RetrievalCriteriaExt

  # ===========================================================================
  # :section: Added attributes
  # ===========================================================================

  public

  # The starting row, which may be given in place of a page.
  #
  # @return [Integer, nil]
  #
  attr_accessor :Offset

  # ===========================================================================
  # :section: EBSCO::EDS::RetrievalCriteria overrides
  # ===========================================================================

  public

  # Override initializer to handle facet pagination.
  #
  # @param [Hash]             options
  # @param [EBSCO::EDS::Info] info
  #
  # This method overrides:
  # @see EBSCO::EDS::RetrievalCriteria#initialize
  #
  # == Usage Notes
  # The caller is expected to have deep-stringified all *options* keys.
  #
  def initialize(options, info)

    options.each do |key, value|

      case key

        # =====================================================================
        # View
        # =====================================================================

        when 'view'
          value = value.to_s.downcase
          @View = (value if info.available_result_list_views.include?(value))

        # =====================================================================
        # Results per page
        # =====================================================================

        when 'rows', 'per_page', 'results_per_page'
          @ResultsPerPage = [value.to_i, info.max_results_per_page].min

        # =====================================================================
        # Page number
        # =====================================================================

        when 'page', 'page_number'
          @PageNumber = value.to_i

        # =====================================================================
        # Row offset
        # =====================================================================

        when 'start'
          @Offset = value.to_i + 1 # Solr starts at row 0; EBSCO at row 1.

        # =====================================================================
        # Highlight
        # =====================================================================

        when 'highlight'
          @Highlight = value.to_s

        when 'hl' # Solr/Blacklight version
          @Highlight = (value == 'on') ? 'y' : 'n'

        # =====================================================================
        # Image quick view
        # =====================================================================

        when 'include_image_quick_view'
          @IncludeImageQuickView = value ? 'y' : 'n'

        # =====================================================================
        # Anything else
        # =====================================================================

        else
          Log.debug {
            "EDS RetrievalCriteria: ignoring param #{key} = #{value.inspect}"
          }

      end

    end

    # API bug: if set to 'n' you won't get research starter abstracts!
    @Highlight = 'y' unless @Highlight.nil?

    # Resolve page versus offset.
    @PageNumber ||= (@Offset / @ResultsPerPage) + 1 if @Offset

    # Apply defaults where values where not explicitly given.
    @IncludeImageQuickView ||= info.default_include_image_quick_view
    @View                  ||= info.default_result_list_view
    @ResultsPerPage        ||= info.default_results_per_page
    @PageNumber            ||= 1

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override EBSCO::EDS::RetrievalCriteria => EBSCO::EDS::RetrievalCriteriaExt

__loading_end(__FILE__)
