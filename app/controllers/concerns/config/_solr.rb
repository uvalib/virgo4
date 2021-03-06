# app/controllers/concerns/config/_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require 'blacklight/solr'

# The baseline configuration for lenses that access items from the local Solr
# production service.
#
# A baseline configuration for a repository contains all possible fields that
# will be needed from the repository.  Individual lens configurations tailor
# information displayed to the user by selecting removing fields from their
# copy of this configuration.
#
class Config::Solr < Config::Base

  # === Music related (facet) fields ===
  MUSIC_TYPES = %w(
    instrument
    music_composition_form
    composition_era
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
  )

  # === Common field values ===
  #
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  #
  # @see Common::Base#semantic_fields!
  #
  # NOTE: Use of these field associations is inconsistent in Blacklight and
  # related gems (and in this application).  Some places expect only a single
  # metadata field name to be associated with the semantic field; others expect
  # (or tolerate) multiple metadata field names (to allow fallback fields to be
  # accessed if the main metadata field is missing or empty).
  #
  SEMANTIC_FIELDS = {
    display_type_field: 'format_a',
    title_field:        'title_a',
    subtitle_field:     %w(subtitle_a title_sub_a),
    alt_title_field:    'title_vern_a',
    author_field:       'author_a',
    alt_author_field:   'author_vern_a',
    thumbnail_field:    'thumbnail_url_a'
  }

  # === Sort field values ===
  #
  BY_AUTHOR      = 'author_ssort'
  BY_CALL_NUMBER = 'call_number_ssort'
  BY_JTITLE      = 'journal_title_ssort'
  BY_RECEIPT     = 'date_received_facet' # TODO: not in index yet
  BY_SCORE       = 'score'
  BY_TITLE       = 'title_ssort'
  BY_YEAR        = 'published_date'

  BY_RECEIVED_DATE   = "#{BY_RECEIPT} desc"
  BY_NEWEST          = "#{BY_YEAR} desc, #{BY_RECEIPT} desc, #{BY_TITLE} asc"
  BY_OLDEST          = "#{BY_YEAR} asc, #{BY_RECEIPT} asc, #{BY_TITLE} asc"
  IN_TITLE_ORDER     = "#{BY_JTITLE} asc, #{BY_TITLE} asc, #{BY_AUTHOR} asc"
  IN_TITLE_REVERSE   = "#{BY_JTITLE} desc, #{BY_TITLE} desc, #{BY_AUTHOR} asc"
  IN_AUTHOR_ORDER    = "#{BY_AUTHOR} asc, #{BY_TITLE} asc"
  IN_AUTHOR_REVERSE  = "#{BY_AUTHOR} desc, #{BY_TITLE} asc"
  IN_SHELF_ORDER     = "#{BY_CALL_NUMBER} asc, #{BY_TITLE} asc"
  IN_SHELF_ORDER_REV = "#{BY_CALL_NUMBER} desc, #{BY_TITLE} asc"
  BY_RELEVANCE       = "#{BY_SCORE} desc, #{BY_NEWEST}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    include Config::Base::ClassMethods

    # Modify a configuration to support searches to the local Solr server.
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

      config.add_facet_field 'library_f'
      config.add_facet_field 'format_f'
      add_facets!(config, VIDEO_TYPES)
      config.add_facet_field 'author_f'
      add_facets!(config, MUSIC_TYPES)
      config.add_facet_field 'subject_f'
      config.add_facet_field 'subject_era_f'
      config.add_facet_field 'collection_f'
      config.add_facet_field 'digital_collection_f'
      config.add_facet_field 'call_number_broad_f'
      config.add_facet_field 'call_number_narrow_f'
      config.add_facet_field 'language_f'
      config.add_facet_field 'region_f'
      config.add_facet_field 'published_date_f'
      config.add_facet_field 'use_f'
      config.add_facet_field 'license_class_f'
      config.add_facet_field 'rights_f'
      config.add_facet_field 'source_f'
      config.add_facet_field 'location2_f'
      config.add_facet_field 'alternate_id_f',       if: :json_request?
      config.add_facet_field 'barcode_f',            if: :json_request?
      config.add_facet_field 'category_f',           if: :json_request?
      config.add_facet_field 'date_first_indexed_f', if: :json_request?
      config.add_facet_field 'date_indexed_f',       if: :json_request?
      config.add_facet_field 'date_received_f',      if: :json_request?
      config.add_facet_field 'doc_type_f',           if: :json_request?
      config.add_facet_field 'feature_f',            if: :json_request?
      config.add_facet_field 'fund_code_f',          if: :json_request?
      config.add_facet_field 'genre_f',              if: :json_request?
      config.add_facet_field 'group_f',              if: :json_request?
      config.add_facet_field 'has_optional_f',       if: :json_request?
      config.add_facet_field 'issn_f',               if: :json_request?
      config.add_facet_field 'location_f',           if: :json_request?
      config.add_facet_field 'marc_display_f',       if: :json_request?
      config.add_facet_field 'media_retrieval_id_f', if: :json_request?
      config.add_facet_field 'oclc_f',               if: :json_request?
      config.add_facet_field 'policy_f',             if: :json_request?
      config.add_facet_field 'released_f',           if: :json_request?
      config.add_facet_field 'series_title_f',       if: :json_request?
      config.add_facet_field 'shadowed_location_f',  if: :json_request?
      config.add_facet_field 'signature_f',          if: :json_request?
      config.add_facet_field 'subject_genre_f',      if: :json_request?
      config.add_facet_field 'title_f',              if: :json_request?
      config.add_facet_field 'topic_form_genre_f',   if: :json_request?

      # === Unimplemented facets
      # config.add_facet_field 'anchor_script_facet'
      # config.add_facet_field 'aspace_version_facet'
      # config.add_facet_field 'author_prev_facet'
      # config.add_facet_field 'author_sort_facet'
      # config.add_facet_field 'belongs_to_facet'
      # config.add_facet_field 'book_plate_facet'
      # config.add_facet_field 'call_number_facet'
      # config.add_facet_field 'content_model_facet'
      # config.add_facet_field 'content_type_facet'
      # config.add_facet_field 'format_diff_facet'
      # config.add_facet_field 'format_extra_facet'
      # config.add_facet_field 'format_old_facet'
      # config.add_facet_field 'format_orig_facet'
      # config.add_facet_field 'guide_book_facet'
      # config.add_facet_field 'hierarchy_level_facet'
      # config.add_facet_field 'libloctype_facet'
      # config.add_facet_field 'ml_number_facet'
      # config.add_facet_field 'music_catagory_facet'
      # config.add_facet_field 'music_composition_era_facet'
      # config.add_facet_field 'ports_of_call_facet'
      # config.add_facet_field 'recording_format_facet'
      # config.add_facet_field 'recording_type_facet'
      # config.add_facet_field 'recordings_and_scores_facet'
      # config.add_facet_field 'torchbearer_facet'
      # config.add_facet_field 'video_director_facet'
      # config.add_facet_field 'video_genre_facet'
      # config.add_facet_field 'video_rating_facet'
      # config.add_facet_field 'year_facet'
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
            when 'title_series_f'       then 15 # NOTE: not in index
            else                             20
          end

        # NOTE: Temporarily "turn off" all JSON-only facets.
        # In total, this brings initial load time of the main page down to
        # ~7 seconds from ~12 seconds.  (Note that actually commenting-out the
        # facet definition does not improve load times over simply setting the
        # facet limit to zero.)
        field.limit = 0 if field.respond_to?(:if) && field.if == :json_request?

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
            when 'year_multisort_i'     then 0..9 # NOTE: not in index
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

      config.add_index_field 'title_a',              if: :json_request?
      config.add_index_field 'subtitle_a',           if: :json_request?
      config.add_index_field 'title_vern_a',         if: :json_request?
      config.add_index_field 'subtitle_vern_a',      if: :json_request? # NOTE: not in index
      config.add_index_field 'title_sub_a',          if: :json_request?
      config.add_index_field 'format_a',             helper_method: :format_facet_label
      config.add_index_field 'author_vern_a'
      config.add_index_field 'author_a'
      config.add_index_field 'language_a'
      config.add_index_field 'published_date_a'
      config.add_index_field 'published_daterange'
      config.add_index_field 'digital_collection_a'
      config.add_index_field 'library_a'
      config.add_index_field 'location_a'
      config.add_index_field 'call_number_a'
      config.add_index_field 'url_a',                helper_method: :url_link

      # === Unimplemented fields
      # config.add_index_field 'score'
      # config.add_index_field 'year_display'

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

      config.add_show_field 'full_title_a',          if: :json_request?
      config.add_show_field 'title_a',               if: :json_request?
      config.add_show_field 'title_vern_a',          if: :json_request?
      config.add_show_field 'title_sub_a',           if: :json_request?
      config.add_show_field 'subtitle_a',            if: :json_request?
      config.add_show_field 'subtitle_vern_a',       if: :json_request? # NOTE: not in index
      config.add_show_field 'author_a',              if: :json_request?
      config.add_show_field 'author_vern_a',         if: :json_request?
      config.add_show_field 'format_a',              helper_method: :format_facet_label
      config.add_show_field 'format_orig_a'
      config.add_show_field 'genre_a'
      config.add_show_field 'title_uniform_a'
      config.add_show_field 'title_added_entry_a'
      config.add_show_field 'title_alternate_a'
      config.add_show_field 'title_series_a'
      config.add_show_field 'series_title_a'
      config.add_show_field 'journal_title_a'
      config.add_show_field 'journal_title_addnl_a'
      config.add_show_field 'journal_addnl_title_a'
      config.add_show_field 'creator_a'              # NOTE: Only for Libra ETD
      config.add_show_field 'author_full_a'
      config.add_show_field 'author_added_entry_a'
      config.add_show_field 'ctb_a'
      config.add_show_field 'author_director_a'
      config.add_show_field 'video_director_a'
      config.add_show_field 'degree_a'
      config.add_show_field 'sponsoring_agency_a'
      config.add_show_field 'grant_info_a'
      config.add_show_field 'year_a'
      config.add_show_field 'startDate_t'            # NOTE: no 'startDate_a'
      config.add_show_field 'endDate_t'              # NOTE: no 'endDate_a'
      config.add_show_field 'date_t'                 # NOTE: no 'date_a'
      config.add_show_field 'published_a'
      config.add_show_field 'published_date_a'
      config.add_show_field 'published_daterange'
      config.add_show_field 'production_date_a'
      config.add_show_field 'date_coverage_a'
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
      config.add_show_field 'media_retrieval_id_a'
      config.add_show_field 'isbn_a'
      config.add_show_field 'isbn_isbn_a'
      config.add_show_field 'issn_a'
      config.add_show_field 'lccn_a'
      config.add_show_field 'oclc_t'
      config.add_show_field 'region_a'
      config.add_show_field 'denomination_a'
      config.add_show_field 'mint_a'
      config.add_show_field 'collection_f'
      config.add_show_field 'digital_collection_a'
      config.add_show_field 'abstract_a'
      config.add_show_field 'category_a'
      config.add_show_field 'group_a'
      config.add_show_field 'signature_a'
      config.add_show_field 'subject_a',             helper_method: :search_link
      config.add_show_field 'subject_era_a'
      config.add_show_field 'subject_summary_a'
      config.add_show_field 'topic_form_genre_a'
      config.add_show_field 'title_notes_a'
      config.add_show_field 'local_notes_a'
      config.add_show_field 'accession_a'
      config.add_show_field 'note_a'
      config.add_show_field 'notes_a'
      config.add_show_field 'media_description_a'
      config.add_show_field 'desc_meta_file_a'
      config.add_show_field 'url_a',                 helper_method: :url_link
      config.add_show_field 'url_supp_a',            helper_method: :url_link
      config.add_show_field 'pda_catkey_a'
      config.add_show_field 'pda_coutts_library_a'
      config.add_show_field 'pda_isbn_a'
      config.add_show_field 'local_rights_statement_a'
      config.add_show_field 'access_a'
      config.add_show_field 'use_a'
      config.add_show_field 'license_class_a'
      config.add_show_field 'cc_type_a'
      config.add_show_field 'cc_uri_a',              helper_method: :url_link
      config.add_show_field 'rights_a'
      config.add_show_field 'rights_url_a',          helper_method: :url_link
      config.add_show_field 'rs_uri_a',              helper_method: :url_link
      config.add_show_field 'rights_wrapper_a'
      config.add_show_field 'rights_wrapper_url_a',  helper_method: :url_link
      config.add_show_field 'library_a'
      config.add_show_field 'location_a'
      config.add_show_field 'location2_a'
      config.add_show_field 'fund_code_a'
      config.add_show_field 'barcode_e'              # NOTE: no 'barcode_a'
      config.add_show_field 'shadowed_location_a'
      config.add_show_field 'summary_holdings_a'
      config.add_show_field 'iiif_presentation_metadata_a'
      config.add_show_field 'shelfkey'
      config.add_show_field 'reverse_shelfkey'
      config.add_show_field 'date_received_a'
      config.add_show_field 'date_indexed_a'
      config.add_show_field 'date_first_indexed_a'
      config.add_show_field 'marc_error_a'
      config.add_show_field 'call_number_broad_a',   if: :json_request?
      config.add_show_field 'call_number_narrow_a',  if: :json_request?
      config.add_show_field 'doc_type_a',            if: :json_request?
      config.add_show_field 'fullrecord',            if: :json_request?
      config.add_show_field 'hathi_id_a',            if: :json_request?
      config.add_show_field 'instrument_raw_a',      if: :json_request?
      config.add_show_field 'main_title_a',          if: :json_request?
      config.add_show_field 'source_a',              if: :json_request?
      config.add_show_field 'thumbnail_url_a',       if: :json_request?

      # === Unimplemented fields
      # config.add_show_field 'act_display'
      # config.add_show_field 'admin_meta_file_display'
      # config.add_show_field 'anchor_script_display'
      # config.add_show_field 'anchor_script_pdf_url_display'
      # config.add_show_field 'anchor_script_thumbnail_url_display'
      # config.add_show_field 'aus_display'
      # config.add_show_field 'aut_display'
      # config.add_show_field 'availability_display'
      # config.add_show_field 'avalon_url_display'
      # config.add_show_field 'book_plate_name_display'
      # config.add_show_field 'book_plate_thumb_url_display'
      # config.add_show_field 'book_plate_url_display'
      # config.add_show_field 'breadcrumbs_display'
      # config.add_show_field 'cmp_display'
      # config.add_show_field 'cnd_display'
      # config.add_show_field 'cng_display'
      # config.add_show_field 'collection_title_display'
      # config.add_show_field 'container_display'
      # config.add_show_field 'content_model_facet'
      # config.add_show_field 'content_type_facet'
      # config.add_show_field 'contributor_display'
      # config.add_show_field 'cre_display'
      # config.add_show_field 'created_date_display'
      # config.add_show_field 'custom_show_field_display'
      # config.add_show_field 'datafile_name_display'
      # config.add_show_field 'description_display'
      # config.add_show_field 'description_note_display'
      # config.add_show_field 'despined_barcodes_display'
      # config.add_show_field 'digitized_item_pid_display'
      # config.add_show_field 'display_aspect_ratio_display'
      # config.add_show_field 'drt_display'
      # config.add_show_field 'dst_display'
      # config.add_show_field 'duration_display'
      # config.add_show_field 'edition_display'
      # config.add_show_field 'editor_display'
      # config.add_show_field 'edt_display'
      # config.add_show_field 'extent_display'
      # config.add_show_field 'feature_display'
      # config.add_show_field 'full_hierarchy_display'
      # config.add_show_field 'geographic_subject_display'
      # config.add_show_field 'hathi_id_display'
      # config.add_show_field 'hierarchy_display'
      # config.add_show_field 'hierarchy_level_display'
      # config.add_show_field 'hst_display'
      # config.add_show_field 'id'
      # config.add_show_field 'individual_call_number_display'
      # config.add_show_field 'issued_date_display'
      # config.add_show_field 'itr_display'
      # config.add_show_field 'ive_display'
      # config.add_show_field 'keywords_display'
      # config.add_show_field 'linked_author_display'
      # config.add_show_field 'linked_responsibility_statement_display'
      # config.add_show_field 'linked_title_display'
      # config.add_show_field 'media_resource_id_display'
      # config.add_show_field 'media_type_display'
      # config.add_show_field 'medium_display'
      # config.add_show_field 'mod_display'
      # config.add_show_field 'modified_chicago_citation_display'
      # config.add_show_field 'msd_display'
      # config.add_show_field 'mus_display'
      # config.add_show_field 'music_catagory_facet'
      # config.add_show_field 'nrt_display'
      # config.add_show_field 'online_url_display'
      # config.add_show_field 'pan_display'
      # config.add_show_field 'part_aspect_ratio_display'
      # config.add_show_field 'part_display'
      # config.add_show_field 'part_duration_display'
      # config.add_show_field 'part_label_display'
      # config.add_show_field 'part_pid_display'
      # config.add_show_field 'pbcore_display'
      # config.add_show_field 'pdf_url_display'
      # config.add_show_field 'physical_form_display'
      # config.add_show_field 'pre_display'
      # config.add_show_field 'prn_display'
      # config.add_show_field 'pro_display'
      # config.add_show_field 'publisher_display'
      # config.add_show_field 'raw_ead_display'
      # config.add_show_field 'related_item_display'
      # config.add_show_field 'repository_address_display'
      # config.add_show_field 'resource_display'
      # config.add_show_field 'responsibility_statement_display'
      # config.add_show_field 'scope_content_display'
      # config.add_show_field 'scopecontent_display'
      # config.add_show_field 'score'
      # config.add_show_field 'sng_display'
      # config.add_show_field 'special_collections_holding_display'
      # config.add_show_field 'spk_display'
      # config.add_show_field 'tei_url_display'
      # config.add_show_field 'temporal_subject_display'
      # config.add_show_field 'terms_of_use_display'
      # config.add_show_field 'timestamp'
      # config.add_show_field 'toc_display'
      # config.add_show_field 'unit_display'
      # config.add_show_field 'upc_display'
      # config.add_show_field 'upc_full_display'
      # config.add_show_field 'video_run_time_display'
      # config.add_show_field 'video_target_audience_display'

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

=begin
      # NOTE: No "journal_title_qf/journal_title_pf" in select_edismax.xml
      config.add_search_field('journal') do |field|
        field.solr_parameters = {
          'spellcheck.dictionary': 'journal',
          qf: '${journal_title_qf}',
          pf: '${journal_title_pf}'
        }
      end

      # NOTE: No "keyword_qf/keyword_pf" in select_edismax.xml
      config.add_search_field('keyword') do |field|
        field.solr_parameters = {
          # 'spellcheck.dictionary': 'keyword',
          qf: '${keyword_qf}',
          pf: '${keyword_pf}',
        }
      end

      # NOTE: No "call_number_qf/call_number_pf" in select_edismax.xml
      config.add_search_field('call_number') do |field|
        field.solr_parameters = {
          qf: '${call_number_qf}',
          pf: '${call_number_pf}'
        }
      end

      # NOTE: No "published_qf/published_pf" in select_edismax.xml
      config.add_search_field('published') do |field|
        field.solr_parameters = {
          # 'spellcheck.dictionary': 'published',
          qf: '${published_qf}',
          pf: '${published_pf}'
        }
      end

      # NOTE: ???
      config.add_search_field('publication_date') do |field|
        field.range        = 'true'
        field.solr_field   = 'year_multisort_i'
        field.autocomplete = false
      end

      # NOTE: No "issn_qf/issn_pf" in select_edismax.xml
      config.add_search_field('issn') do |field|
        field.solr_parameters = {
          qf: '${issn_qf}',
          pf: '${issn_pf}'
        }
        field.autocomplete = false
      end

      # NOTE: No "isbn_qf/isbn_pf" in select_edismax.xml
      config.add_search_field('isbn') do |field|
        field.solr_parameters = {
          qf: '${isbn_qf}',
          pf: '${isbn_pf}'
        }
        field.autocomplete = false
      end
=end

      # NOTE: No "isbn_issn_pf" in select_edismax.xml (does that matter?)
      config.add_search_field('isbn_issn') do |field|
        field.solr_parameters = {
          qf: '${isbn_issn_qf}',
          pf: '${isbn_issn_pf}'
        }
        field.autocomplete = false
      end

      # "All Fields" search selection is intentionally placed last so that the
      # user will be encouraged to arrive at a more appropriate search type
      # before falling-back on a generic keyword search.  It is indicated as
      # "default" only to ensure that other search types are properly labeled
      # in search constraints and history.
      config.add_search_field('all_fields') do |field|
        field.default      = true
        field.autocomplete = 'defaultSuggest'
      end

      # Initialize search field :autocomplete settings.
      config.search_fields.each_pair do |key, field|
        field.autocomplete = "#{key}Suggest" if field.autocomplete.nil?
      end

      # =======================================================================
      # Sort fields
      # =======================================================================

      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      config.add_sort_field 'relevance',        sort: BY_RELEVANCE
      config.add_sort_field 'received',         sort: BY_RECEIVED_DATE
      config.add_sort_field 'newest',           sort: BY_NEWEST
      config.add_sort_field 'oldest',           sort: BY_OLDEST
      config.add_sort_field 'title',            sort: IN_TITLE_ORDER
      config.add_sort_field 'title_rev',        sort: IN_TITLE_REVERSE
      config.add_sort_field 'author',           sort: IN_AUTHOR_ORDER
      config.add_sort_field 'author_rev',       sort: IN_AUTHOR_REVERSE
      config.add_sort_field 'call_number',      sort: IN_SHELF_ORDER
      config.add_sort_field 'call_number_rev',  sort: IN_SHELF_ORDER_REV

      # =======================================================================
      # Search parameters
      # =======================================================================

      search_builder_processors!(config)
      autocomplete_suggesters!(config)

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
      values =
        Blacklight::OpenStructWithHashAccess.new(
          document_factory:      Blacklight::Solr::DocumentFactory,
          document_model:        SolrDocument,
          field_retriever_class: Blacklight::Solr::FieldRetriever,
          repository_class:      Blacklight::Solr::Repository,
          response_model:        Blacklight::Solr::Response,
          search_builder_class:  SearchBuilderSolr,
        )
      values = values.merge(added_values) if added_values.present?
      super(config, values)
    end

    # Set the filter query parameters for the lens.
    #
    # @param [Blacklight::Configuration] config
    # @param [Array<Symbol>]             values
    #
    # @return [void]
    #
    # @see SearchBuilderSolr#
    #
    def search_builder_processors!(config, *values)
      values += %i(public_only discoverable_only)
      super(config, values)
    end

    # Settings for autocomplete suggesters.
    #
    # @param [Blacklight::Configuration] config
    #
    # @return [void]
    #
    # This method overrides:
    # @see Config::Base::ClassMethods#autocomplete_suggesters!
    #
    def autocomplete_suggesters!(config)
      config.autocomplete_path      = 'suggest'
      config.autocomplete_suggester = 'defaultSuggest'
      super(config, '%sSuggest')
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
    # == Usage Notes
    # This holds the engine-generated code that would be specific to the Solr
    # search repository, however the parts relating to OpenSeaDragon are unused
    # and currently untested.  This could/should be adapted to our IIIF setup.
    #
    def blacklight_gallery!(config)
      super(config)
      config.view.slideshow.partials = [:index_header]
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
  # from the local Solr server.
  #
  # @param [Blacklight::Lens::Controller] controller
  #
  def initialize(controller)
    production_solr(true)
    @blacklight_config = build_configuration(controller)
    super(@blacklight_config)
  end

end

__loading_end(__FILE__)
