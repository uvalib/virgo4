# app/controllers/concerns/config/_solr.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr/repository_ext'
require_relative '_common'

class Config::Solr

  include Config::Common
  extend  Config::Common

  # Default Blacklight Lens for controllers based on this configuration.
  SOLR_DEFAULT_LENS = :catalog

  # === Common field values ===
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  SOLR_FIELD = {
    display_type_field: :format_facet,  # TODO: Could remove to avoid partial lookups by display type if "_default" is the only appropriate partial.
    title_field:        %i(main_title_display title_display),
    subtitle_field:     :subtitle_display,
    alt_title_field:    :linked_title_display,
    author_field:       %i(
                          responsibility_statement_display
                          author_display
                          author_facet
                        ),
    alt_author_field:   %i(
                          linked_responsibility_statement_display
                          linked_author_display
                          linked_author_facet
                        ),
    thumbnail_field:    %i(thumbnail_url_display),
  }

  # === Sort field values ===
  #
  BY_YEAR        = :year_multisort_i
  BY_RECEIPT     = :date_received_facet
  BY_TITLE       = :title_sort_facet
  BY_AUTHOR      = :author_sort_facet
  BY_CALL_NUMBER = :call_number_sort_facet
  BY_SCORE       = :score

  BY_RECEIVED_DATE   = "#{BY_RECEIPT} desc"
  BY_NEWEST          = "#{BY_YEAR} desc, #{BY_RECEIPT} desc"
  BY_OLDEST          = "#{BY_YEAR} asc, #{BY_RECEIPT} asc"
  IN_TITLE_ORDER     = "#{BY_TITLE} asc, #{BY_AUTHOR} asc"
  IN_AUTHOR_ORDER    = "#{BY_AUTHOR} asc, #{BY_TITLE} asc"
  IN_SHELF_ORDER     = "#{BY_CALL_NUMBER} asc"
  IN_REV_SHELF_ORDER = "#{BY_CALL_NUMBER} desc"
  BY_RELEVANCE       = "#{BY_SCORE} desc, #{BY_NEWEST}"

  # ===========================================================================
  # :section:
  # ===========================================================================

  # The Blacklight configuration for lenses using Solr search.
  #
  # @return [Blacklight::Configuration]
  #
  # @see Blacklight::Configuration#default_values
  #
  def self.instance
    # rubocop:disable Metrics/LineLength
    production_solr(true)
    @instance ||= Blacklight::Configuration.new do |config|

      include Config::Common
      extend  Config::Common

      # Default Blacklight Lens for controllers based on this configuration.
      config.lens_key = SOLR_DEFAULT_LENS

      # === Search request configuration ===

      # HTTP method to use when making requests to Solr; valid values are
      # :get and :post.
      #config.http_method = :get

      # Solr path which will be added to Solr base URL before the other Solr
      # params.
      #config.solr_path = 'select'

      # Default parameters to send to Solr for all search-like requests.
      # @see Blacklight::SearchBuilder#processed_parameters
      config.default_solr_params = {
        qt:   'search',
        rows: 10,
        #'facet.sort': 'index' # Sort by byte order rather than by count.
      }

      # === Single document request configuration ===

      # The Solr request handler to use when requesting only a single document.
      #config.document_solr_request_handler = 'document'

      # The path to send single document requests to Solr (if different than
      # 'config.solr_path').
      #config.document_solr_path = nil

      # Primary key for indexed documents.
      #config.document_unique_id_param = :id

      # Default parameters to send on single-document requests to Solr. These
      # settings are the Blacklight defaults (see SearchHelper#solr_doc_params)
      # or parameters included in the Blacklight-jetty document requestHandler.
      #config.default_document_solr_params = {
      #  qt: 'document',
      #  ## These are hard-coded in the blacklight 'document' requestHandler
      #  # fl: '*',
      #  # rows: 1,
      #  # q: '{!term f=id v=$id}'
      #}

      # Base Solr parameters for pagination of single documents.
      # @see Blacklight::RequestBuilders#previous_and_next_document_params
      #config.document_pagination_params = {}

      # === Response models ===

      # Class for sending and receiving requests from a search index.
      config.repository_class = Blacklight::Solr::RepositoryExt

      # Class for converting Blacklight's URL parameters into request
      # parameters for the search index via repository_class.
      config.search_builder_class = ::SearchBuilder

      # Model that maps search index responses to Blacklight responses.
      config.response_model = Blacklight::Solr::Response

      # The model to use for each response document.
      config.document_model = SolrDocument

      # Class for paginating long lists of facet fields.
      config.facet_paginator_class = Blacklight::Solr::FacetPaginator

      # Repository connection configuration.
      # NOTE: For the standard catalog this is based on blacklight.yml;
      # for alternate lenses this might allow for an alternate Solr to be
      # accessed by providing an alternate blacklight.yml.
      #config.connection_config = ...

      # === Configuration for navbar ===
      # @see Blacklight::Configuration#add_nav_action

      #config.navbar = OpenStructWithHashAccess.new(partials: {})

      # === Configuration for search results/index views ===
      # @see Blacklight::Configuration::ViewConfig::Index

      config.index.document_presenter_class = Blacklight::IndexPresenterExt
      config.index.display_type_field = SOLR_FIELD[:display_type_field]
      config.index.title_field        = SOLR_FIELD[:title_field]
      config.index.subtitle_field     = SOLR_FIELD[:subtitle_field]
      config.index.alt_title_field    = SOLR_FIELD[:alt_title_field]
      config.index.author_field       = SOLR_FIELD[:author_field]
      config.index.alt_author_field   = SOLR_FIELD[:alt_author_field]
      config.index.thumbnail_field    = SOLR_FIELD[:thumbnail_field].last

      # === Configuration for document/show views ===
      # @see Blacklight::Configuration::ViewConfig::Show

      config.show.document_presenter_class = Blacklight::ShowPresenterExt
      config.show.display_type_field  = SOLR_FIELD[:display_type_field]
      config.show.title_field         = SOLR_FIELD[:title_field]
      config.show.subtitle_field      = SOLR_FIELD[:subtitle_field]
      config.show.alt_title_field     = SOLR_FIELD[:alt_title_field]
      config.show.author_field        = SOLR_FIELD[:author_field]
      config.show.alt_author_field    = SOLR_FIELD[:alt_author_field]
      config.show.thumbnail_field     = SOLR_FIELD[:thumbnail_field]
      config.show.partials            = [:show_header, :thumbnail, :show]

      # === Configurations for specific types of index views ===
      # @see Blacklight::Configuration#view_config

      #config.view =
      #  Blacklight::NestedOpenStructWithHashAccess.new(
      #    Blacklight::Configuration::ViewConfig,
      #    'list',
      #    atom: { if: false, partials: [:document] },
      #    rss:  { if: false, partials: [:document] },
      #  )

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

      config.add_facet_field :library_facet
      config.add_facet_field :format_facet
      config.add_facet_field :author_facet
      config.add_facet_field :subject_facet
      config.add_facet_field :series_title_facet
      config.add_facet_field :digital_collection_facet
      config.add_facet_field :call_number_broad_facet
      config.add_facet_field :language_facet
      config.add_facet_field :region_facet
      config.add_facet_field :published_date_facet
      config.add_facet_field :category_facet
      config.add_facet_field :group_facet
      config.add_facet_field :signature_facet
      config.add_facet_field :use_facet
      config.add_facet_field :license_class_facet
      config.add_facet_field :source_facet
      config.add_facet_field :location2_facet
      config.add_facet_field :year_multisort_i
      config.add_facet_field :collection_facet         # TODO: testing; remove
      config.add_facet_field :call_number_facet        # TODO: testing; remove?
      config.add_facet_field :location_facet           # TODO: testing; remove
      config.add_facet_field :torchbearer_facet        # TODO: testing; remove
      config.add_facet_field :ml_number_facet          # TODO: testing; remove

      # Set labels from locale for this lens and supply options that apply to
      # multiple field configurations.
      config.facet_fields.each_pair do |key, field|

        key = key.to_sym

        case key
          when :library_facet            then -1 # Show all libraries.
          when :author_facet             then 10
          when :series_title_facet       then 15
          when :digital_collection_facet then 10
          when :call_number_broad_facet  then 15
          else                                20
        end.tap { |limit| field.limit = limit if limit }

        case key
          when :library_facet            then 'index'
          when :call_number_broad_facet  then 'index'
          else                                'count'
        end.tap { |sort| field.sort = sort if sort }

        case key
          when :alternate_form_title_facet  then "\x20".."\x7E"
          when :author_facet                then "\x20".."\x7E"
          when :genre_facet                 then "\x20".."\x7E"
          when :journal_title_facet         then "\x20".."\x7E"
          when :location_facet              then "\x20".."\x7E"
          when :location2_facet             then "\x20".."\x7E"
          when :region_facet                then "\x20".."\x7E"
          when :series_title_facet          then "\x20".."\x7E"
          when :subject_facet               then "\x20".."\x7E"
          when :topic_form_genre_facet      then "\x20".."\x7E"
          when :uniform_title_facet         then "\x20".."\x7E"
          when :call_number_broad_facet     then nil
          when :year_multisort_i            then 0..9
          else                              'A'..'Z'
        end.tap { |range| field.index_range = range if range }

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
      # [1] IndexPresenterExt#label shows :main_title_display, :title_display,
      #     :subtitle_display, and :linked_title_display so they should not be
      #     included here.

      config.add_index_field :format_facet, helper_method: :format_facet_label
      config.add_index_field :linked_author_display
      config.add_index_field :author_display
      config.add_index_field :language_facet
      config.add_index_field :year_display
      config.add_index_field :published_date_display
      config.add_index_field :digital_collection_facet
      config.add_index_field :library_facet
      config.add_index_field :location_facet
      config.add_index_field :call_number_display
      config.add_index_field :url_display, helper_method: :url_link
      #config.add_index_field :id
      config.add_index_field :score

      # === Item details (show page) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] ShowPresenterExt#heading shows :main_title_display, :title_display,
      #     :subtitle_display, :linked_title_display,
      #     :responsibility_statement_display and
      #     :linked_responsibility_statement_display so they should not be
      #     included here.
      #
      # [2] :collection_title_display appears to have the same value as
      #     :digital_collection_facet so they do not both need to be included.
      #
      # [3] :date_coverage_display appears to have the same value as
      #     :published_date_display so they do not both need to be included.
      #
      # [4] :cre_display appears to have the same value as :author_facet so
      #     they do not both need to be included.

      config.add_show_field :format_facet, helper_method: :format_facet_label
      config.add_show_field :medium_display
      config.add_show_field :recording_format_facet
      config.add_show_field :part_display
      config.add_show_field :journal_title_facet
      config.add_show_field :uniform_title_facet
      config.add_show_field :alternate_form_title_facet
      config.add_show_field :series_title_facet
      config.add_show_field :digital_collection_facet
      config.add_show_field :degree_display
      config.add_show_field :recording_type_facet
      config.add_show_field :music_composition_form_facet
      config.add_show_field :music_catagory_facet
      config.add_show_field :mus_display
      config.add_show_field :video_genre_facet
      config.add_show_field :genre_facet
      config.add_show_field :published_date_display
      config.add_show_field :language_facet
      config.add_show_field :langauge_facet
      config.add_show_field :media_resource_id_display
      config.add_show_field :published_display
      config.add_show_field :author_facet
      config.add_show_field :release_date_facet
      config.add_show_field :duration_display
      config.add_show_field :video_run_time_display
      config.add_show_field :video_rating_facet
      config.add_show_field :video_director_facet
      config.add_show_field :accession_display
      config.add_show_field :denomination_display
      config.add_show_field :collection_facet
      config.add_show_field :abstract_display
      config.add_show_field :description_note_display
      config.add_show_field :title_added_entry_display
      config.add_show_field :toc_display
      config.add_show_field :note_display
      config.add_show_field :subject_facet
      config.add_show_field :topic_form_genre_facet
      config.add_show_field :subject_era_facet
      config.add_show_field :region_facet
      config.add_show_field :media_description_display
      config.add_show_field :media_retrieval_id_facet
      config.add_show_field :isbn_display
      config.add_show_field :issn_display
      config.add_show_field :oclc_display
      config.add_show_field :upc_display
      config.add_show_field :url_display, helper_method: :url_link
      config.add_show_field :library_facet
      config.add_show_field :location_facet
      config.add_show_field :location2_facet
      config.add_show_field :unit_display
      config.add_show_field :url_supp_display, helper_method: :url_link
      config.add_show_field :call_number_display
      config.add_show_field :call_number_orig_display
      config.add_show_field :call_number_facet
      config.add_show_field :call_number_sort_facet
      config.add_show_field :lc_call_number_display
      config.add_show_field :shelfkey
      config.add_show_field :reverse_shelfkey
      config.add_show_field :use_facet
      config.add_show_field :license_class_facet
      config.add_show_field :terms_of_use_display
      config.add_show_field :summary_holdings_display
      config.add_show_field :published_date_facet
      config.add_show_field :shadowed_location_facet
      config.add_show_field :alternate_id_facet
      config.add_show_field :doc_type_facet
      config.add_show_field :content_model_facet
      config.add_show_field :content_type_facet
      config.add_show_field :feature_facet
      config.add_show_field :individual_call_number_display
      config.add_show_field :iiif_presentation_metadata_display
      config.add_show_field :rights_wrapper_display
      config.add_show_field :rights_wrapper_url_display, helper_method: :url_link
      config.add_show_field :rs_uri_display,  helper_method: :url_link
      config.add_show_field :pdf_url_display, helper_method: :url_link
      config.add_show_field :avalon_url_display
      config.add_show_field :part_pid_display
      config.add_show_field :part_label_display
      config.add_show_field :part_duration_display
      config.add_show_field :issued_date_display
      config.add_show_field :created_date_display
      config.add_show_field :breadcrumbs_display
      config.add_show_field :hierarchy_level_display
      config.add_show_field :hierarchy_display
      config.add_show_field :full_hierarchy_display
      config.add_show_field :pbcore_display
      config.add_show_field :scope_content_display
      config.add_show_field :repository_address_display
      config.add_show_field :datafile_name_display
      config.add_show_field :admin_meta_file_display
      config.add_show_field :desc_meta_file_display
      config.add_show_field :raw_ead_display
      config.add_show_field :source_facet
      config.add_show_field :barcode_facet
      config.add_show_field :fund_code_facet
      config.add_show_field :date_first_indexed_facet
      config.add_show_field :timestamp
      config.add_show_field :date_indexed_facet
      config.add_show_field :id
      config.add_show_field :score

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

      config.add_search_field(:title) do |field|
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'title', # TODO: ?
          qf: '$qf_title', #qf: '${qf_title}', # TODO: Solr 7.x
          pf: '$pf_title', #pf: '${pf_title}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:author) do |field|
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'author', # TODO: ?
          qf: '$qf_author', #qf: '${qf_author}', # TODO: Solr 7.x
          pf: '$pf_author', #pf: '${pf_author}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:subject) do |field|
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'subject', # TODO: ?
          qf: '$qf_subject', #qf: '${qf_subject}', # TODO: Solr 7.x
          pf: '$pf_subject', #pf: '${pf_subject}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:journal) do |field|
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'journal', # TODO: ?
          qf: '$qf_journal_title', #qf: '${qf_journal_title}', # TODO: Solr 7.x
          pf: '$pf_journal_title', #pf: '${pf_journal_title}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:keyword) do |field| # TODO: testing - remove?
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'keyword', # TODO: ?
          qf: '$qf_keyword', #qf: '${qf_keyword}', # TODO: Solr 7.x
          pf: '$pf_keyword', #pf: '${pf_keyword}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:call_number) do |field| # TODO: testing - remove?
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'call_number', # TODO: ?
          qf: '$qf_call_number', #qf: '${qf_call_number}', # TODO: Solr 7.x
          pf: '$pf_call_number', #pf: '${pf_call_number}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:published) do |field| # TODO: testing - remove?
        field.solr_local_parameters = {
          #'spellcheck.dictionary': 'published', # TODO: ?
          qf: '$qf_published', #qf: '${qf_published}', # TODO: Solr 7.x
          pf: '$pf_published', #pf: '${pf_published}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:publication_date) do |field| # TODO: testing - remove?
        field.range      = 'true'
        field.solr_field = 'year_multisort_i'
      end

      config.add_search_field(:issn) do |field| # TODO: testing - remove?
        field.solr_local_parameters = {
          qf: '$qf_issn', #qf: '${qf_issn}', # TODO: Solr 7.x
          pf: '$pf_issn', #pf: '${pf_issn}', # TODO: Solr 7.x
        }
      end

      config.add_search_field(:isbn) do |field| # TODO: testing - remove?
        field.solr_local_parameters = {
          qf: '$qf_isbn', #qf: '${qf_isbn}', # TODO: Solr 7.x
          pf: '$pf_isbn', #pf: '${pf_isbn}', # TODO: Solr 7.x
        }
      end

      # "All Fields" search selection is intentionally placed last so that the
      # user will be encouraged to arrive at a more appropriate search type
      # before falling-back on a generic keyword search.  It is indicated as
      # "default" only to ensure that other search types are properly labeled
      # in search constraints and history.
      config.add_search_field :all_fields, default: true

      # === Sort fields ===
      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      config.add_sort_field :relevance,       sort: BY_RELEVANCE
      config.add_sort_field :received,        sort: BY_RECEIVED_DATE
      config.add_sort_field :newest,          sort: BY_NEWEST
      config.add_sort_field :oldest,          sort: BY_OLDEST
      config.add_sort_field :title,           sort: IN_TITLE_ORDER
      config.add_sort_field :author,          sort: IN_AUTHOR_ORDER
      config.add_sort_field :call_number,     sort: IN_SHELF_ORDER
      config.add_sort_field :call_number_rev, sort: IN_REV_SHELF_ORDER

      # === Blacklight behavior configuration ===

      # If there are more than this many search results, no "did you mean"
      # suggestion is offered.
      config.spell_max = 10 # NOTE: was 5

      # Maximum number of results to show per page.
      #config.max_per_page: 100

      # Items to show per page, each number in the array represent another
      # option to choose from.
      #config.per_page = [10, 20, 50, 100]

      # Default :per_page selection
      #config.default_per_page = nil

      # How many searches to save in session history.
      #config.search_history_window = 100

      # The default number of items to show in a facet value menu when the
      # facet field does not specify a :limit.
      #config.default_facet_limit = 10

      # The facets with more than this number of values get a "more>>" link.
      # This the number of items per page in the facet modal dialog.
      config.default_more_limit = 15 # config.default_facet_limit # NOTE: was 20

      # Configuration for suggester.
      config.autocomplete_enabled = true
      config.autocomplete_path    = 'suggest'

      # === Blacklight Advanced Search ===

      config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
      #config.advanced_search.qt                  ||= 'search'
      config.advanced_search.url_key              ||= 'advanced'
      config.advanced_search.query_parser         ||= 'dismax'
      config.advanced_search.form_solr_parameters ||= {}
=begin
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

      finalize_configuration(config)

    end
    # rubocop:enable Metrics/LineLength
  end

end

__loading_end(__FILE__)
