# app/controllers/concerns/config/_solr_fake.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_solr'

# A baseline configuration for lenses that access items from a desktop Solr
# instance (for example, based on the test Solr configuration in solr/conf in
# this project directory).
#
# A baseline configuration for a repository contains all possible fields that
# will be needed from the repository.  Individual lens configurations tailor
# information displayed to the user by selecting removing fields from their
# copy of this configuration.
#
class Config::SolrFake < Config::Base

  # === Common field values ===
  #
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  #
  # @see #semantic_fields!
  #
  # NOTE: Use of these field associations is inconsistent in Blacklight and
  # related gems (and in this application).  Some places expect only a single
  # metadata field name to be associated with the semantic field; others expect
  # (or tolerate) multiple metadata field names (to allow fallback fields to be
  # accessed if the main metadata field is missing or empty).
  #
  SEMANTIC_FIELDS = {
    display_type_field: 'format',
    title_field:        'title_display',
    subtitle_field:     nil,
    alt_title_field:    nil,
    author_field:       nil,
    alt_author_field:   nil,
    thumbnail_field:    'thumbnail_path_ss'
  }

  # === Sort field values ===
  #
  BY_AUTHOR = 'author_sort'
  BY_SCORE  = 'score'
  BY_TITLE  = 'title_sort'
  BY_YEAR   = 'pub_date_sort'

  BY_NEWEST         = "#{BY_YEAR} desc, #{BY_TITLE} asc"
  BY_OLDEST         = "#{BY_YEAR} asc, #{BY_TITLE} asc"
  IN_TITLE_ORDER    = "#{BY_TITLE} asc, #{BY_AUTHOR} asc"
  IN_TITLE_REVERSE  = "#{BY_TITLE} desc, #{BY_AUTHOR} asc"
  IN_AUTHOR_ORDER   = "#{BY_AUTHOR} asc, #{BY_TITLE} asc"
  IN_AUTHOR_REVERSE = "#{BY_AUTHOR} desc, #{BY_TITLE} asc"
  BY_RELEVANCE      = "#{BY_SCORE} desc, #{BY_NEWEST}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods
    include Config::Base::ClassMethods

    # Modify a configuration to support searches to a desktop Solr instance.
    #
    # @param [Blacklight::Configuration]     config
    # @param [Blacklight::Controller, Class] controller
    #
    # @return [Blacklight::Configuration]   The modified configuration.
    #
    # @see Config::Solr#response_models!
    # @see Config::Base#add_tools!
    # @see Config::Base#finalize_configuration!
    #
    def configure!(config, controller)
      # rubocop:disable Metrics/LineLength

      # Common configuration values.
      super(config, controller)

      # =======================================================================
      # Lens
      # =======================================================================

      # Default Blacklight Lens for controllers based on this configuration.
      config.lens_key = :catalog

      response_models!(config)

      # =======================================================================
      # Facets
      # =======================================================================

      # Solr fields that will be treated as facets by the application.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      config.add_facet_field 'format',              label: 'Format'
      config.add_facet_field 'pub_date',            label: 'Publication Year', single: true
      config.add_facet_field 'subject_topic_facet', label: 'Topic', limit: 20, index_range: 'A'..'Z'
      config.add_facet_field 'language_facet',      label: 'Language', limit: true
      config.add_facet_field 'lc_1letter_facet',    label: 'Call Number'
      config.add_facet_field 'subject_geo_facet',   label: 'Region'
      config.add_facet_field 'subject_era_facet',   label: 'Era'

      # === Experimental facets
      now = Time.zone.now.year
      config.add_facet_field 'example_query_facet_field', query: {
        years_5:  { label: 'within 5 Years',  fq: "pub_date:[#{now-5}  TO *]" },
        years_10: { label: 'within 10 Years', fq: "pub_date:[#{now-10} TO *]" },
        years_25: { label: 'within 25 Years', fq: "pub_date:[#{now-25} TO *]" }
      }, label: 'Publication Range'

      config.add_facet_field(
        'example_pivot_field',
        label: 'Pivot Field',
        pivot: %w(format language_facet),
        unless: :json_request?
      )

      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # =======================================================================
      # Index pages (search results)
      # =======================================================================

      # === Index metadata fields ===
      # Solr fields to be displayed in the index (search results) view.
      # (The ordering of the field names is the order of the display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] Blacklight::Lens::IndexPresenter#label shows title and format so
      #     they should not be included here for HTML -- only for JSON.

      config.add_index_field 'title_display',           label: 'Title',          helper_method: :raw_value, if: :json_request?
      config.add_index_field 'subtitle_display',        label: 'Subtitle',       helper_method: :raw_value, if: :json_request?
      config.add_index_field 'title_vern_display',      label: 'Title',          helper_method: :raw_value, if: :json_request?
      config.add_index_field 'subtitle_vern_display',   label: 'Subtitle',       helper_method: :raw_value, if: :json_request?
      config.add_index_field 'format',                  label: 'Format',         helper_method: :format_facet_label
      config.add_index_field 'author_display',          label: 'Author'
      config.add_index_field 'author_vern_display',     label: 'Author'
      config.add_index_field 'language_facet',          label: 'Language'
      config.add_index_field 'published_display',       label: 'Published'
      config.add_index_field 'published_vern_display',  label: 'Published'
      config.add_index_field 'lc_callnum_display',      label: 'Call number'

      # =======================================================================
      # Show pages (item details)
      # =======================================================================

      # === Show page (item details) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] Blacklight::Lens::ShowPresenter#heading shows title and author so
      #     they should not be included here for HTML -- only for JSON.

      config.add_show_field 'title_display',          label: 'Title',            helper_method: :raw_value, if: :json_request?
      config.add_show_field 'title_vern_display',     label: 'Title',            helper_method: :raw_value, if: :json_request?
      config.add_show_field 'subtitle_display',       label: 'Subtitle',         helper_method: :raw_value, if: :json_request?
      config.add_show_field 'subtitle_vern_display',  label: 'Subtitle',         helper_method: :raw_value, if: :json_request?
      config.add_show_field 'author_display',         label: 'Author',           helper_method: :raw_value, if: :json_request?
      config.add_show_field 'author_vern_display',    label: 'Author',           helper_method: :raw_value, if: :json_request?
      config.add_show_field 'format',                 label: 'Format',           helper_method: :format_facet_label
      config.add_show_field 'url_fulltext_display',   label: 'URL',              helper_method: :url_link
      config.add_show_field 'url_suppl_display',      label: 'More Information', helper_method: :url_link
      config.add_show_field 'language_facet',         label: 'Language'
      config.add_show_field 'published_display',      label: 'Published'
      config.add_show_field 'published_vern_display', label: 'Published'
      config.add_show_field 'lc_callnum_display',     label: 'Call number'
      config.add_show_field 'isbn_t',                 label: 'ISBN'

      # =======================================================================
      # Search fields
      # =======================================================================

      # "Fielded" search configuration. Used by pulldown among other places.
      # For supported keys in hash, see rdoc for Blacklight::SearchFields.
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # "All Fields" is intentionally placed last.

      config.add_search_field('title') do |field|
        field.solr_local_parameters = {
          'spellcheck.dictionary': 'title',
          qf: '${title_qf}',
          pf: '${title_pf}'
        }
      end

      config.add_search_field('author') do |field|
        field.solr_local_parameters = {
          'spellcheck.dictionary': 'author',
          qf: '${author_qf}',
          pf: '${author_pf}'
        }
      end

      config.add_search_field('subject') do |field|
        field.solr_local_parameters = {
          'spellcheck.dictionary': 'subject',
          qf: '${subject_qf}',
          pf: '${subject_pf}'
        }
        # Specifying a :qt only to show it's possible, and so our internal
        # automated tests can test it. In this case it's the same as
        # config[:default_solr_parameters][:qt], so isn't actually necessary.
        field.qt = 'search'
      end

      # "All Fields" search selection is intentionally placed last so that the
      # user will be encouraged to arrive at a more appropriate search type
      # before falling-back on a generic keyword search.  It is indicated as
      # "default" only to ensure that other search types are properly labeled
      # in search constraints and history.
      config.add_search_field 'all_fields', label: 'All Fields', default: true

      # =======================================================================
      # Sort fields
      # =======================================================================

      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      config.add_sort_field 'relevance',  sort: BY_RELEVANCE,      label: 'Relevance'
      config.add_sort_field 'newest',     sort: BY_NEWEST,         label: 'Date'
      config.add_sort_field 'oldest',     sort: BY_OLDEST,         label: 'Date (oldest first)'
      config.add_sort_field 'title',      sort: IN_TITLE_ORDER,    label: 'Title'
      config.add_sort_field 'title_rev',  sort: IN_TITLE_REVERSE,  label: 'Title (reverse)'
      config.add_sort_field 'author',     sort: IN_AUTHOR_ORDER,   label: 'Author'
      config.add_sort_field 'author_rev', sort: IN_AUTHOR_REVERSE, label: 'Author (reverse)'

      # =======================================================================
      # Search parameters
      # =======================================================================

      # TODO: ???

      # =======================================================================
      # Blacklight Advanced Search
      # =======================================================================

      # TODO: ???

      # =======================================================================
      # Finalize and return the modified configuration
      # =======================================================================

      add_tools!(config)
      semantic_fields!(config)
      blacklight_gallery!(config)
      finalize_configuration!(config)

      # rubocop:enable Metrics/LineLength
    end

    # Define per-repository response model values and copy them to the top
    # level of the configuration where Blacklight expects to see them.
    #
    # @param [Blacklight::Configuration]                       config
    # @param [Hash, Blacklight::OpenStructWithHashAccess, nil] added_values
    #
    # @return [void]
    #
    # @see Config::Base#response_models!
    #
    def response_models!(config, added_values = nil)
      ::Config::Solr.response_models!(config, added_values)
    end

    # Set mappings of configuration key to repository field for both :index and
    # :show configurations.
    #
    # @param [Blacklight::Configuration]                       config
    # @param [Hash, Blacklight::OpenStructWithHashAccess, nil] added_values
    #
    # @return [void]
    #
    # @see Config::Base#semantic_fields!
    #
    def semantic_fields!(config, added_values = nil)
      values = SEMANTIC_FIELDS
      values = values.merge(added_values) if added_values.present?
      super(config, values)
    end

    # Add configuration for Blacklight::Gallery
    #
    # @param [Blacklight::Configuration] config
    #
    # @return [void]
    #
    # @see Config::Base#blacklight_gallery!
    #
    # == Usage Note
    # This holds the engine-generated code that would be specific to the Solr
    # search repository, however the parts relating to OpenSeaDragon are unused
    # and currently untested.
    #
    def blacklight_gallery!(config)
      super(config)
      config.view.slideshow.partials = %i(index_header)
      config.show.tile_source_field  = :content_metadata_image_iiif_info_ssm
      config.show.partials.insert(1, :openseadragon)
    end

  end

  include ClassMethods
  extend  ClassMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new configuration as the basis for lenses that access items
  # from a desktop Solr instance.
  #
  # @param [Blacklight::Lens::Controller] controller
  #
  def initialize(controller)
    production_solr(false)
    @blacklight_config = build_configuration(controller)
    super(@blacklight_config)
  end

end

__loading_end(__FILE__)
