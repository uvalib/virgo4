# app/controllers/concerns/config/_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'
require 'blacklight/solr'

class Config::Solr

  include ::Config::Common
  extend  ::Config::Common
  include ::Config::Base

  # === Common field values ===
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  SOLR_FIELD = {
    display_type_field: 'format_a', # TODO: Could remove to avoid partial lookups by display type if "_default" is the only appropriate partial.
    title_field:        'title_a',
    subtitle_field:     'subtitle_a',
    alt_title_field:    'title_vern_a',
    author_field:       'author_a',
    alt_author_field:   'author_vern_a',
    thumbnail_field:    'thumbnail_url_display', # TODO: not in index yet
  }
=begin # NOTE: old fields for reference - to be removed
  SOLR_FIELD = {
    display_type_field: 'format_facet',
    title_field:        %w(main_title_display title_display),
    subtitle_field:     'subtitle_display',
    alt_title_field:    'linked_title_display',
    author_field:       %w(
                          responsibility_statement_display
                          author_display
                          author_facet
                        ),
    alt_author_field:   %w(
                          linked_responsibility_statement_display
                          linked_author_display
                          linked_author_facet
                        ),
    thumbnail_field:    %w(thumbnail_url_display),
  }
=end

  # === Sort field values ===
  #
  BY_YEAR        = 'published_date'
  BY_RECEIPT     = 'date_received_facet' # TODO: not in index yet
  BY_TITLE       = 'title_ssort'
  BY_JTITLE      = 'journal_title_ssort'
  BY_AUTHOR      = 'author_ssort'
  BY_CALL_NUMBER = 'call_number_ssort'
  BY_SCORE       = 'score'

  BY_RECEIVED_DATE   = "#{BY_RECEIPT} desc"
  BY_NEWEST          = "#{BY_YEAR} desc, #{BY_RECEIPT} desc"
  BY_OLDEST          = "#{BY_YEAR} asc, #{BY_RECEIPT} asc"
  IN_TITLE_ORDER     = "#{BY_TITLE} asc, #{BY_AUTHOR} asc"
  IN_AUTHOR_ORDER    = "#{BY_AUTHOR} asc, #{BY_TITLE} asc"
  IN_SHELF_ORDER     = "#{BY_CALL_NUMBER} asc"
  IN_REV_SHELF_ORDER = "#{BY_CALL_NUMBER} desc"
  BY_RELEVANCE       = "#{BY_SCORE} desc, #{BY_NEWEST}"

  # === Music related (facet) fields ===
  MUSIC_TYPES = %w(
    composition_era
    instrument
    music_composition_form
    recording_format
    recordings_and_scores
  )

  # === Video related (facet) fields ===
  VIDEO_TYPES = %w(
    author_director
    video_director
    video_genre
    video_rating
    video_run_time
    video_target_audience
  )

  # === Catalog-only (facet) fields ===
  CATALOG_TYPES = %w(
    example_pivot_field
  )

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Modify a base configuration.
  #
  # @param [Blacklight::Configuration]     config
  # @param [Blacklight::Controller, Class] controller
  #
  # @return [Blacklight::Configuration]   The modified configuration.
  #
  def self.configure!(config, controller)
    # rubocop:disable Metrics/LineLength

    config.klass = controller.is_a?(Class) ? controller : controller.class

    # =========================================================================
    # Lens
    # =========================================================================

    # Default Blacklight Lens for controllers based on this configuration.
    config.lens_key = :catalog

    # === Search request configuration ===

    # HTTP method to use when making requests to Solr; valid values are
    # :get and :post.
    # config.http_method = :get

    # Solr path which will be added to Solr base URL before the other Solr
    # params.
    # config.solr_path = 'select'

    # Default parameters to send to Solr for all search-like requests.
    # @see Blacklight::SearchBuilder#processed_parameters
    config.default_solr_params = {
      qt:   'search',
      rows: 10,
      #'facet.sort': 'index' # Sort by byte order rather than by count.
    }

    # === Single document request configuration ===

    # The Solr request handler to use when requesting only a single document.
    # config.document_solr_request_handler = 'document'

    # The path to send single document requests to Solr (if different than
    # 'config.solr_path').
    # config.document_solr_path = 'get'

    # Primary key for indexed documents.
    # config.document_unique_id_param = :ids

    # Default parameters to send on single-document requests to Solr.
    # config.default_document_solr_params = {
    #   qt: 'document',
    #   ## These are hard-coded in the blacklight 'document' requestHandler
    #   # fl: '*',
    #   # rows: 1,
    #   # q: '{!term f=id v=$id}'
    # }

    # Base Solr parameters for pagination of single documents.
    # @see Blacklight::RequestBuilders#previous_and_next_document_params
    # config.document_pagination_params = {}

    # === Response models ===

    config.lens = Blacklight::OpenStructWithHashAccess.new(
      document_model:         SolrDocument,
      document_factory:       Blacklight::Solr::DocumentFactory,
      response_model:         Blacklight::Lens::Response,
      repository_class:       Blacklight::Solr::Repository,
      search_builder_class:   SearchBuilderSolr,
      facet_paginator_class:  Blacklight::Solr::FacetPaginator
    )

    # Class for sending and receiving requests from a search index.
    config.repository_class = config.lens.repository_class

    # Class for converting Blacklight's URL parameters into request
    # parameters for the search index via repository_class.
    config.search_builder_class = config.lens.search_builder_class

    # Model that maps search index responses to Blacklight responses.
    config.response_model = config.lens.response_model

    # The model to use for each response document.
    config.document_model = config.lens.document_model

    # A class that builds documents.
    config.document_factory = config.lens.document_factory

    # Class for paginating long lists of facet fields.
    config.facet_paginator_class = config.lens.facet_paginator_class

    # Repository connection configuration.
    # NOTE: For the standard catalog this is based on blacklight.yml;
    # for alternate lenses this might allow for an alternate Solr to be
    # accessed by providing an alternate blacklight.yml.
    # config.connection_config = nil

    # =========================================================================
    # Metadata fields
    # =========================================================================

    # === Configuration for search results/index views ===
    # @see Blacklight::Configuration::ViewConfig::Index

    config.index.document_presenter_class = Blacklight::Lens::IndexPresenter
    config.index.field_presenter_class    = Blacklight::Lens::FieldPresenter
    config.index.partials                 = %i(index_header index)
=begin # TODO: Thumbnails
    config.index.partials                 = %i(index_header thumbnail index)
=end

    config.index.display_type_field = SOLR_FIELD[:display_type_field]
    config.index.title_field        = SOLR_FIELD[:title_field]
    config.index.subtitle_field     = SOLR_FIELD[:subtitle_field]
    config.index.alt_title_field    = SOLR_FIELD[:alt_title_field]
    config.index.author_field       = SOLR_FIELD[:author_field]
    config.index.alt_author_field   = SOLR_FIELD[:alt_author_field]
    config.index.thumbnail_field    = SOLR_FIELD[:thumbnail_field].last

    # === Configuration for document/show views ===
    # @see Blacklight::Configuration::ViewConfig::Show

    config.show.document_presenter_class = Blacklight::Lens::ShowPresenter
    config.show.field_presenter_class    = Blacklight::Lens::FieldPresenter
    config.show.partials                 = %i(show_header show)
=begin # TODO: Thumbnails
    config.show.partials                 = %i(show_header thumbnail show)
=end

    config.show.display_type_field  = SOLR_FIELD[:display_type_field]
    config.show.title_field         = SOLR_FIELD[:title_field]
    config.show.subtitle_field      = SOLR_FIELD[:subtitle_field]
    config.show.alt_title_field     = SOLR_FIELD[:alt_title_field]
    config.show.author_field        = SOLR_FIELD[:author_field]
    config.show.alt_author_field    = SOLR_FIELD[:alt_author_field]
    config.show.thumbnail_field     = SOLR_FIELD[:thumbnail_field]

    # === Configurations for specific types of index views ===
    # @see Blacklight::Configuration#view_config

    # config.view =
    #   Blacklight::NestedOpenStructWithHashAccess.new(
    #     Blacklight::Configuration::ViewConfig,
    #     'list',
    #     atom: { if: false, partials: [:document] },
    #     rss:  { if: false, partials: [:document] },
    #   )

    # === Facet fields ===
    # Solr fields that will be treated as facets by the application.
    # (The ordering of the field names is the order of display.)
    #
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    #
    # * If left unset, then all facet values returned by Solr will be
    #     displayed.
    #
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    #     Solr request, with actual Solr request being +1 your configured
    #     limit -- you configure the number of items you actually want
    #     _displayed_ in a page.
    #
    # * If set to *true*, then no additional parameters will be sent to Solr,
    #     but any 'sniffed' request limit parameters will be used for paging,
    #     with paging at requested limit -1. Can sniff from facet.limit or
    #     f.specific_field.facet.limit Solr request params. This *true*
    #     config can be used if you set limits in :default_solr_params, or as
    #     defaults on the Solr side in the request handler itself. Request
    #     handler defaults sniffing requires Solr requests to be made with
    #     "echoParams=all", for app code to actually have it echo'd back to
    #     see it.
    #
    # :show may be set to *false* if you don't want the facet to be drawn in
    # the facet bar.
    #
    # Set :index_range to *true* if you want the facet pagination view to
    # have facet prefix-based navigation (useful when user clicks "more" on a
    # large facet and wants to navigate alphabetically across a large set of
    # results).
    #
    # :index_range can be an array or range of prefixes that will be used to
    # create the navigation (Note: It is case sensitive when searching
    # values).
    #
    # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

    config.add_facet_field 'library_f'
    config.add_facet_field 'format_f'
    config.add_facet_field 'author_f'
    config.add_facet_field 'subject_f'
    config.add_facet_field 'call_number_broad_f'
    config.add_facet_field 'call_number_narrow_f'
    config.add_facet_field 'language_f'
    config.add_facet_field 'region_f'
    config.add_facet_field 'published_date'
    config.add_facet_field 'subject_era_f'
    VIDEO_TYPES.each { |type| config.add_facet_field "#{type}_f" }
    MUSIC_TYPES.each { |type| config.add_facet_field "#{type}_f" }
    config.add_facet_field 'source_f'
    config.add_facet_field 'location2_f'

    # === Experimental facets
    config.add_facet_field 'example_query_facet_field', query: {
      years_5:  {
        label: 'within 5 Years',
        fq:    "published_daterange:[#{Time.zone.now.year - 5  } TO *]"
      },
      years_10: {
        label: 'within 10 Years',
        fq:    "published_daterange:[#{Time.zone.now.year - 10 } TO *]"
      },
      years_25: {
        label: 'within 25 Years',
        fq:    "published_daterange:[#{Time.zone.now.year - 25 } TO *]"
      }
    }, label: 'Publication Range'
    config.add_facet_field(
      'example_pivot_field',
      pivot: %w(format_f language_f),
      label: 'Pivot Field'
    )

    # === Unused facets
    # config.add_facet_field 'author_director_f'
    # config.add_facet_field 'barcode_f'
    # config.add_facet_field 'date_indexed_f'
    # config.add_facet_field 'issn_f'
    # config.add_facet_field 'location_f'
    # config.add_facet_field 'oclc_f'
    # config.add_facet_field 'shadowed_location_f'

    # === Unimplemented facets
    # config.add_facet_field 'call_number_facet'
    # config.add_facet_field 'category_facet'
    # config.add_facet_field 'collection_facet'
    # config.add_facet_field 'date_first_indexed_facet'
    # config.add_facet_field 'date_received_facet'
    # config.add_facet_field 'digital_collection_f'
    # config.add_facet_field 'fund_code_facet'
    # config.add_facet_field 'group_facet'
    # config.add_facet_field 'license_class_facet'
    # config.add_facet_field 'location_facet'
    # config.add_facet_field 'ml_number_facet'
    # config.add_facet_field 'series_title_f'
    # config.add_facet_field 'signature_facet'
    # config.add_facet_field 'torchbearer_facet'
    # config.add_facet_field 'use_facet'
    # config.add_facet_field 'year_multisort_i'

    # Set labels from locale for this lens and supply options that apply to
    # multiple field configurations.
    config.facet_fields.each_pair do |key, field|

      field.limit =
        case key
          when 'author_f'             then 10
          when 'call_number_broad_f'  then 15
          when 'digital_collection_f' then 10
          when 'library_f'            then -1 # Show all libraries.
          when 'series_title_f'       then 15
          else                             20
        end

      field.sort =
        case key
          when 'call_number_broad_f'  then 'index'
          when 'library_f'            then 'index'
          else                             'count'
        end

      field.index_range =
        case key
          when 'author_f'             then "\x20".."\x7E"
          when 'call_number_broad_f'  then nil
          when 'location2_f'          then "\x20".."\x7E"
          when 'location_f'           then "\x20".."\x7E"
          when 'region_f'             then "\x20".."\x7E"
          when 'subject_f'            then "\x20".."\x7E"
          when 'topic_form_genre_f'   then "\x20".."\x7E"
          when 'year_multisort_i'     then 0..9
          else                             'A'..'Z'
        end


      # NOTE: The following fields need to have their values capitalized
      # (that is, the data needs to be capitalized when acquired) so that you
      # don't need to have an index_range that includes both upper- and
      # lowercase letters in order to access the entire gamut of values:
      #
      #                             !"#$%&'()*+,-./ 0123456789 :;<=>?@ A-Z [\]^_` a-z {|}~
      #                             --------------- ---------- ------- --- ------ --- ----
      # alternate_form_title_facet  YYYY_YYY_YY_YYY YYYYYYYYYY Y_Y__YY YYY YY___Y YYY ____
      # author_facet                _YYYYYYYYYYYYYY YYYYYYYYYY Y_YYYYY YYY YYY__Y YYY ____
      # genre_facet                 _______Y_____Y_ YYYY___Y_Y _______ YYY Y_____ YYY ____
      # journal_title_facet         _______________ YYYYYYYYYY _______ ___ ______ YYY ____
      # location_facet              _______________ __YY______ _______ YYY ______ ___ ____
      # location2_facet             _______________ ___Y______ _______ YYY ______ ___ ____
      # region_facet                _Y____YY_Y__YY_ YYYYYYYYYY __YY___ YYY ______ YYY ____
      # series_title_facet          YYYYYYYYYYYYYY_ YYYYYYYYYY Y_YY_YY YYY YY__YY YYY YY__
      # subject_facet               YYYY_YYY_YYYYY_ YYYYYYYYYY Y_Y_YY_ YYY Y_____ YYY ____
      # topic_form_genre_facet      YY_Y__YY_YYYYY_ YYYYYYYYYY __Y__YY YYY Y_____ YYY ____
      # uniform_title_facet         YYY___YY_Y__YYY YYYYYYYYYY ___Y_YY YYY Y_____ YYY ____
      #
      # (The starting letter of values for other facets checked were within
      # the range 'A'..'Z'.)

    end

    # === Index (results page) metadata fields ===
    # Solr fields to be displayed in the index (search results) view.
    # (The ordering of the field names is the order of the display.)
    #
    # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
    #
    # ==== Implementation Notes
    # [1] Blacklight::Lens::IndexPresenter#label shows 'title_a',
    #     'subtitle_a', and 'title_vern_a' so they should be included here for
    #     JSON but not for HTML.

    config.add_index_field 'title_a',          helper_method: :raw_value, if: :json_request?
    config.add_index_field 'subtitle_a',       helper_method: :raw_value, if: :json_request?
    config.add_index_field 'title_vern_a',     helper_method: :raw_value, if: :json_request?
    config.add_index_field 'subtitle_vern_a',  helper_method: :raw_value, if: :json_request?
    config.add_index_field 'format_a',         helper_method: :format_facet_label
    config.add_index_field 'author_vern_a'
    config.add_index_field 'author_a'
    config.add_index_field 'language_a'
    config.add_index_field 'published_date'
    config.add_index_field 'digital_collection_a'
    config.add_index_field 'library_a'
    config.add_index_field 'location_a'
    config.add_index_field 'call_number_a'
    config.add_index_field 'url_a',       helper_method: :url_link

    # === Unimplemented fields
    # config.add_index_field 'id'
    # config.add_index_field 'score'
    # config.add_index_field 'year_display'

    # === Item details (show page) metadata fields ===
    # Solr fields to be displayed in the show (single result) view.
    # (The ordering of the field names is the order of display.)
    #
    # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
    #
    # ==== Implementation Notes
    # [1] Blacklight::Lens::ShowPresenter#heading shows 'title_a',
    #     'subtitle_a', 'title_vern_a', 'author_a', 'author_vern_a' so they
    #     should included here for JSON but not for HTML.

    config.add_show_field 'title_a',              helper_method: :raw_value, if: :json_request?
    config.add_show_field 'title_vern_a',         helper_method: :raw_value, if: :json_request?
    config.add_show_field 'subtitle_a',           helper_method: :raw_value, if: :json_request?
    config.add_show_field 'subtitle_vern_a',      helper_method: :raw_value, if: :json_request?
    config.add_show_field 'author_a',             helper_method: :raw_value, if: :json_request?
    config.add_show_field 'author_vern_a',        helper_method: :raw_value, if: :json_request?
    config.add_show_field 'author_added_entry_a'
    config.add_show_field 'author_director_a'
    config.add_show_field 'video_director_a'
    config.add_show_field 'format_a',             helper_method: :format_facet_label
    config.add_show_field 'title_uniform_a'
    config.add_show_field 'title_series_a'
    config.add_show_field 'title_added_entry_a'
    config.add_show_field 'title_alternate_a'
    config.add_show_field 'journal_title_a'
    config.add_show_field 'journal_addnl_title_a'
    config.add_show_field 'published_date'
    config.add_show_field 'date_bulk_coverage_a'
    config.add_show_field 'composition_era_a'
    config.add_show_field 'music_composition_form_a'
    config.add_show_field 'form_a'
    config.add_show_field 'instrument_a'
    config.add_show_field 'video_genre_a'
    config.add_show_field 'video_rating_a'
    config.add_show_field 'video_run_time_a'
    config.add_show_field 'video_target_audience_a'
    config.add_show_field 'release_a'
    config.add_show_field 'language_a'
    config.add_show_field 'lc_call_number_a'
    config.add_show_field 'call_number_a'
    config.add_show_field 'isbn_a'
    config.add_show_field 'isbn_isbn_a'
    config.add_show_field 'issn_a'
    config.add_show_field 'lccn_a'
    config.add_show_field 'oclc_t'
    config.add_show_field 'region_a'
    config.add_show_field 'subject_a'
    config.add_show_field 'subject_era_a'
    config.add_show_field 'subject_summary_a'
    config.add_show_field 'topic_form_genre_a'
    config.add_show_field 'title_notes_a'
    config.add_show_field 'local_notes_a'
    config.add_show_field 'url_a',                helper_method: :url_link
    config.add_show_field 'url_supp_a',           helper_method: :url_link
    config.add_show_field 'location'
    config.add_show_field 'pda_catkey_a'
    config.add_show_field 'pda_coutts_library_a'
    config.add_show_field 'pda_isbn_a'
    config.add_show_field 'barcode_e'
    config.add_show_field 'summary_holdings_a'
    config.add_show_field 'shadowed_location_a'
    config.add_show_field 'shelfkey'
    config.add_show_field 'reverse_shelfkey'
    config.add_show_field 'marc_error_a'
    config.add_show_field 'date_indexed_a'
    config.add_show_field 'fullrecord',           helper_method: :raw_value, if: :json_request?

    # === Unused fields
    # config.add_show_field 'library_facet'
    # config.add_show_field 'location_facet'
    # config.add_show_field 'call_number_broad_a'
    # config.add_show_field 'call_number_narrow_a'
    # config.add_show_field 'instrument_raw_a'
    # config.add_show_field 'source_f'

    # === Unimplemented fields
    # config.add_show_field 'abstract_display'
    # config.add_show_field 'accession_display'
    # config.add_show_field 'admin_meta_file_display'
    # config.add_show_field 'alternate_id_facet'
    # config.add_show_field 'author_facet'
    # config.add_show_field 'avalon_url_display'
    # config.add_show_field 'breadcrumbs_display'
    # config.add_show_field 'collection_facet'
    # config.add_show_field 'content_model_facet'
    # config.add_show_field 'content_type_facet'
    # config.add_show_field 'created_date_display'
    # config.add_show_field 'datafile_name_display'
    # config.add_show_field 'date_first_indexed_facet'
    # config.add_show_field 'degree_display'
    # config.add_show_field 'denomination_display'
    # config.add_show_field 'desc_meta_file_display'
    # config.add_show_field 'description_note_display'
    # config.add_show_field 'digital_collection_facet'
    # config.add_show_field 'doc_type_facet'
    # config.add_show_field 'duration_display'
    # config.add_show_field 'feature_facet'
    # config.add_show_field 'full_hierarchy_display'
    # config.add_show_field 'fund_code_facet'
    # config.add_show_field 'genre_facet'
    # config.add_show_field 'hierarchy_display'
    # config.add_show_field 'hierarchy_level_display'
    # config.add_show_field 'id'
    # config.add_show_field 'iiif_presentation_metadata_display'
    # config.add_show_field 'individual_call_number_display'
    # config.add_show_field 'issued_date_display'
    # config.add_show_field 'license_class_facet'
    # config.add_show_field 'media_description_display'
    # config.add_show_field 'media_resource_id_display'
    # config.add_show_field 'media_retrieval_id_facet'
    # config.add_show_field 'medium_display'
    # config.add_show_field 'mus_display'
    # config.add_show_field 'music_catagory_facet'
    # config.add_show_field 'note_display'
    # config.add_show_field 'part_display'
    # config.add_show_field 'part_duration_display'
    # config.add_show_field 'part_label_display'
    # config.add_show_field 'part_pid_display'
    # config.add_show_field 'pbcore_display'
    # config.add_show_field 'pdf_url_display',            helper_method: :url_link
    # config.add_show_field 'published_display'
    # config.add_show_field 'raw_ead_display'
    # config.add_show_field 'recording_format_facet'
    # config.add_show_field 'recording_type_facet'
    # config.add_show_field 'release_date_facet'
    # config.add_show_field 'repository_address_display'
    # config.add_show_field 'rights_wrapper_display'
    # config.add_show_field 'rights_wrapper_url_display', helper_method: :url_link
    # config.add_show_field 'rs_uri_display',             helper_method: :url_link
    # config.add_show_field 'scope_content_display'
    # config.add_show_field 'score'
    # config.add_show_field 'terms_of_use_display'
    # config.add_show_field 'timestamp'
    # config.add_show_field 'toc_display'
    # config.add_show_field 'unit_display'
    # config.add_show_field 'upc_display'
    # config.add_show_field 'use_facet'

    # === Search fields ===
    # "Fielded" search configuration. Used by pulldown among other places.
    # For supported keys in hash, see rdoc for Blacklight::SearchFields.
    #
    # Search fields will inherit the :qt Solr request handler from
    # config[:default_solr_parameters], OR can specify a different one with a
    # :qt key/value. Below examples inherit, except for subject that
    # specifies the same :qt as default for our own internal testing
    # purposes.
    #
    # The :key is what will be used to identify this BL search field
    # internally, as well as in URLs -- so changing it after deployment may
    # break bookmarked URLs.  A display label will be automatically
    # calculated from the :key, or can be specified manually to be different.
    #
    # This one uses all the defaults set by the Solr request handler. Which
    # Solr request handler? The one set in
    # config[:default_solr_parameters][:qt], since we aren't specifying it
    # otherwise.
    #
    # Now we see how to over-ride Solr request handler defaults, in this case
    # for a BL "search field", which is really a dismax aggregate of Solr
    # search fields.
    #
    # :solr_parameters are sent to Solr as ordinary URL query params.
    #
    # :solr_local_parameters are sent using Solr LocalParams syntax, e.g:
    # "{! qf=$qf_title }". This is necessary to use Solr parameter
    # de-referencing like $qf_title.
    # @see http://wiki.apache.org/solr/LocalParams
    #
    # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
    #
    # ==== Implementation Notes
    # "All Fields" is intentionally placed last.

    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params.
      field.solr_parameters = {
        'spellcheck.dictionary': 'title',
        qf: '${title_qf}',
        pf: '${title_pf}'
      }
    end

    config.add_search_field('author') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'author',
        qf: '${author_qf}',
        pf: '${author_pf}'
      }
    end

    config.add_search_field('subject') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'subject',
        qf: '${subject_qf}',
        pf: '${subject_pf}'
      }
    end

=begin # TODO: No "journal_title_qf/journal_title_pf" in select_edismax.xml
    config.add_search_field('journal') do |field|
      field.solr_parameters = {
        'spellcheck.dictionary': 'journal',
        qf: '${journal_title_qf}',
        pf: '${journal_title_pf}'
      }
    end
=end

=begin # TODO: No "keyword_qf/keyword_pf" in select_edismax.xml
    config.add_search_field('keyword') do |field| # TODO: testing - remove?
      field.solr_local_parameters = {
        #'spellcheck.dictionary': 'keyword', # TODO: ?
        qf: '${keyword_qf}',
        pf: '${keyword_pf}',
      }
    end
=end

=begin # TODO: No "call_number_qf/call_number_pf" in select_edismax.xml
    config.add_search_field('call_number') do |field|
      field.solr_parameters = {
        qf: '${call_number_qf}',
        pf: '${call_number_pf}'
      }
    end
=end

=begin # TODO: No "published_qf/published_pf" in select_edismax.xml
    config.add_search_field('published') do |field|
      field.solr_local_parameters = {
        #'spellcheck.dictionary': 'published', # TODO: ?
        qf: '${published_qf}',
        pf: '${published_pf}'
      }
    end
=end

=begin # TODO: ???
    config.add_search_field('publication_date') do |field|
      field.range      = 'true'
      field.solr_field = 'year_multisort_i'
    end
=end

=begin # TODO: No "issn_qf/issn_pf" in select_edismax.xml
    config.add_search_field('issn') do |field|
      field.solr_local_parameters = {
        qf: '${issn_qf}',
        pf: '${issn_pf}'
      }
    end
=end

=begin # TODO: No "isbn_qf/isbn_pf" in select_edismax.xml
    config.add_search_field('isbn') do |field|
      field.solr_local_parameters = {
        qf: '${isbn_qf}',
        pf: '${isbn_pf}'
      }
    end
=end

    # TODO: No "isbn_issn_pf" in select_edismax.xml (does that matter?)
    config.add_search_field('isbn_issn') do |field|
      field.label = 'ISBN/ISSN'
      field.solr_parameters = {
        qf: '${isbn_issn_qf}',
        pf: '${isbn_issn_pf}'
      }
    end

    # "All Fields" search selection is intentionally placed last so that the
    # user will be encouraged to arrive at a more appropriate search type
    # before falling-back on a generic keyword search.  It is indicated as
    # "default" only to ensure that other search types are properly labeled
    # in search constraints and history.
    config.add_search_field 'all_fields', label: 'All Fields', default: true

    # === Sort fields ===
    # "Sort results by" select (pulldown)
    # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

    config.add_sort_field 'relevance',        sort: BY_RELEVANCE
    config.add_sort_field 'received',         sort: BY_RECEIVED_DATE
    config.add_sort_field 'newest',           sort: BY_NEWEST
    config.add_sort_field 'oldest',           sort: BY_OLDEST
    config.add_sort_field 'title',            sort: IN_TITLE_ORDER
    config.add_sort_field 'author',           sort: IN_AUTHOR_ORDER
    config.add_sort_field 'call_number',      sort: IN_SHELF_ORDER
    config.add_sort_field 'call_number_rev',  sort: IN_REV_SHELF_ORDER

    # =========================================================================
    # Search
    # =========================================================================

    # If there are more than this many search results, no "did you mean"
    # suggestion is offered.
    config.spell_max = 10 # NOTE: was 5

    # Maximum number of results to show per page.
    # config.max_per_page: 100

    # Items to show per page, each number in the array represent another
    # option to choose from.
    # config.per_page = [10, 20, 50, 100]

    # Default :per_page selection
    # config.default_per_page = nil

    # How many searches to save in session history.
    # config.search_history_window = 100

    # The default number of items to show in a facet value menu when the
    # facet field does not specify a :limit.
    # config.default_facet_limit = 10

    # The facets with more than this number of values get a "more>>" link.
    # This the number of items per page in the facet modal dialog.
    config.default_more_limit = 15 # config.default_facet_limit # NOTE: was 20

    # Configuration for suggester.
    # TODO: Cope with different suggesters for different search fields...
    config.autocomplete_suggester = 'titleSuggest'
    #config.autocomplete_suggester = 'authorSuggester'
    #config.autocomplete_suggester = 'subjectSuggester'
    config.autocomplete_enabled   = true
    config.autocomplete_path      = 'suggest'

    # =========================================================================
    # Blacklight Advanced Search
    # =========================================================================

    config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
    # config.advanced_search.qt                 ||= 'search'
    config.advanced_search.url_key              ||= 'advanced'
    config.advanced_search.query_parser         ||= 'dismax'
    config.advanced_search.form_solr_parameters ||= {}
=begin # NOTE: old fields for reference - to be removed
    config.advanced_search = Blacklight::OpenStructWithHashAccess.new(
      qt:           'search',
      url_key:      'advanced',
      query_parser: 'dismax',
      form_solr_parameters: {
        'facet.field': %w(
          format
          pub_date
          subject_topic_facet
          language_facet
          lc_alpha_facet
          subject_geo_facet
          subject_era_facet
        ),
        'facet.limit': -1,     # return all facet values
        'facet.sort':  'index' # sort by byte order of values
      }
    )
=end

    # === Localization ===
    # Get field labels from I18n, including labels specific to this lens.

    # =========================================================================
    # Finalize and return the modified configuration
    # =========================================================================

    add_tools!(config)
    finalize_configuration!(config)

    # rubocop:enable Metrics/LineLength
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  attr_reader :blacklight_config

  delegate_missing_to(:blacklight_config)

  def initialize(controller)
    production_solr(true)
    @blacklight_config =
      Blacklight::Configuration.new do |config|
        self.class.configure!(config, controller)
      end
  end

end

__loading_end(__FILE__)
