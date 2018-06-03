# app/controllers/concerns/config/_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'catalog'
require 'blacklight/eds'

module Config::Eds

  # Default Blacklight Lens for controllers based on this configuration.
  EDS_DEFAULT_LENS = :articles

  # === Common field values ===
  # Certain "index" and "show" configuration fields have the same values based
  # on the relevant fields defined by the search service.
  EDS_FIELD = {
    display_type_field: :eds_publication_type,  # TODO: Could remove to avoid partial lookups by display type if "_default" is the only appropriate partial.
    title_field:        :eds_title,
    subtitle_field:     :eds_other_titles,      # TODO: ???
    alt_title_field:    nil,                    # TODO: ???
    author_field:       :eds_authors,
    alt_author_field:   nil,                    # TODO: ???
    thumbnail_field:    %i(eds_cover_medium_url eds_cover_thumb_url),
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  # The Blacklight configuration for lenses using EBSCO EDS search.
  #
  # This derives from the configuration for the Catalog lens.
  #
  # @return [Blacklight::Configuration]
  #
  # @see Config::Catalog#CATALOG_CONFIG
  # @see Blacklight::Configuration#default_values
  #
  def self.instance
    # rubocop:disable Metrics/LineLength
    @instance ||= Config::Catalog.new.deep_copy.tap do |config|

      include Config::Common
      extend  Config::Common

      # Specify the Blacklight Lens key for this configuration.
      config.lens_key = EDS_DEFAULT_LENS

      # === Search request configuration ===

      # === Single document request configuration ===

      # === Response models ===

      # Class for sending and receiving requests from a search index.
      config.repository_class = Blacklight::Eds::Repository

      # Class for converting Blacklight's URL parameters into request
      # parameters for the search index via repository_class.
      config.search_builder_class = ::SearchBuilderEds

      # Model that maps search index responses to Blacklight responses.
      config.response_model = Blacklight::Eds::Response

      # The model to use for each response document.
      config.document_model = EdsDocument

      # Class for paginating long lists of facet fields.
      #config.facet_paginator_class = Blacklight::Solr::FacetPaginator

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

      #config.index.document_presenter_class = Blacklight::IndexPresenterExt
      config.index.display_type_field = EDS_FIELD[:display_type_field]
      config.index.title_field        = EDS_FIELD[:title_field]
      config.index.subtitle_field     = EDS_FIELD[:subtitle_field]
      config.index.alt_title_field    = EDS_FIELD[:alt_title_field]
      config.index.author_field       = EDS_FIELD[:author_field]
      config.index.alt_author_field   = EDS_FIELD[:alt_author_field]
      config.index.thumbnail_field    = EDS_FIELD[:thumbnail_field].last

      # === Configuration for document/show views ===
      # @see Blacklight::Configuration::ViewConfig::Show

      #config.show.document_presenter_class = Blacklight::ShowPresenterExt
      config.show.display_type_field  = EDS_FIELD[:display_type_field]
      config.show.title_field         = EDS_FIELD[:title_field]
      config.show.subtitle_field      = EDS_FIELD[:subtitle_field]
      config.show.alt_title_field     = EDS_FIELD[:alt_title_field]
      config.show.author_field        = EDS_FIELD[:author_field]
      config.show.alt_author_field    = EDS_FIELD[:alt_author_field]
      config.show.thumbnail_field     = EDS_FIELD[:thumbnail_field]
      #config.show.partials           = [:show_header, :thumbnail, :show]

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
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      # Remove the fields that were set by Config::Catalog.
      config.facet_fields.clear

      config.add_facet_field :eds_search_limiters_facet
      config.add_facet_field :eds_library_location_facet
      config.add_facet_field :eds_library_collection_facet
      config.add_facet_field :eds_author_university_facet
      config.add_facet_field :eds_publication_type_facet
      config.add_facet_field :eds_publication_year_facet #, single: true
      config.add_facet_field :eds_publication_year_range_facet, single: true # TODO: testing
      config.add_facet_field :eds_category_facet
      config.add_facet_field :eds_subject_topic_facet
      config.add_facet_field :eds_language_facet
      config.add_facet_field :eds_journal_facet
      config.add_facet_field :eds_subjects_geographic_facet
      config.add_facet_field :eds_publisher_facet
      config.add_facet_field :eds_content_provider_facet

      # Set labels from locale for this lens and supply options that apply to
      # multiple field configurations.
      config.facet_fields.each_pair do |key, field|

        key = key.to_sym

        case key
          when :eds_search_limiters_facet then -1
          else                                 20
        end.tap { |limit| field.limit = limit if limit }

        case key
          when :eds_search_limiters_facet then 'index'
          else                                 'count'
        end.tap { |sort| field.sort = sort if sort }

        case key
          when :eds_search_limiters_facet then 'A'..'Z'
          #else                                 'A'..'Z'
          else                                 "\x20".."\x7E"
        end.tap { |range| field.index_range = range if range }

      end

      # === Index (results page) metadata fields ===
      # Solr fields to be displayed in the index (search results) view.
      # (The ordering of the field names is the order of the display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] IndexPresenterExt#label shows :eds_title so it should not be
      #     included here.
      #
      # [2] 'Published in' (:eds_composed_title), if present, eliminates the
      #     need for separate :eds_source_title, :eds_publication_info, and
      #     :eds_publication_date entries.

      # Remove the fields that were set by Config::Catalog.
      config.index_fields.clear

      config.add_index_field :eds_publication_type,        helper_method: :eds_publication_type_label
      config.add_index_field :eds_authors
      config.add_index_field :eds_composed_title,          helper_method: :eds_index_publication_info
      config.add_index_field :eds_languages
      config.add_index_field :eds_html_fulltext_available, helper_method: :fulltext_link
      #config.add_index_field :id
      config.add_index_field :eds_relevancy_score

      # === Item details (show page) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] ShowPresenterExt#heading shows :eds_title and :eds_authors so they
      #     should not be included here.
      #
      # [2] 'Published in' (:eds_composed_title), if present, eliminates the
      #     need for separate :eds_source_title, :eds_publication_info, and
      #     :eds_publication_date entries.
      #
      # [3] :eds_result_id is only meaningful in search results so it's not
      #     included here.

      # Remove the fields that were set by Config::Catalog.
      config.show_fields.clear

      config.add_show_field :eds_publication_type,     helper_method: :eds_publication_type_label
      config.add_show_field :eds_document_type          # TODO: Cope with extraneous text (e.g. "Artikel<br>PeerReviewed")
      config.add_show_field :eds_publication_status
      config.add_show_field :eds_other_titles
      config.add_show_field :eds_composed_title
      config.add_show_field :eds_languages
      config.add_show_field :eds_source_title
      config.add_show_field :eds_series
      config.add_show_field :eds_publication_year
      config.add_show_field :eds_volume
      config.add_show_field :eds_issue
      config.add_show_field :eds_page_count
      config.add_show_field :eds_start_page
      config.add_show_field :eds_publication_info
      config.add_show_field :eds_publisher
      config.add_show_field :eds_publication_date
      config.add_show_field :eds_document_doi,         helper_method: :doi_link
      config.add_show_field :eds_document_oclc
      config.add_show_field :eds_issns
      config.add_show_field :eds_isbns
      config.add_show_field :eds_all_links,            helper_method: :all_eds_links
      config.add_show_field :eds_plink,                helper_method: :ebsco_eds_plink
      #config.add_show_field :eds_fulltext_links,      helper_method: :best_fulltext # NOTE: not working right
      config.add_show_field :eds_abstract
      config.add_show_field :eds_notes
      config.add_show_field :eds_physical_description
      config.add_show_field :eds_html_fulltext,        helper_method: :html_fulltext
      config.add_show_field :eds_publication_type_id
      config.add_show_field :eds_access_level
      config.add_show_field :eds_authors_composed
      config.add_show_field :eds_author_affiliations
      config.add_show_field :eds_issn_print
      config.add_show_field :eds_isbn_print
      config.add_show_field :eds_isbn_electronic
      config.add_show_field :eds_isbns_related
      config.add_show_field :eds_subjects
      config.add_show_field :eds_subjects_geographic
      config.add_show_field :eds_subjects_person
      config.add_show_field :eds_subjects_company
      config.add_show_field :eds_subjects_bisac
      config.add_show_field :eds_subjects_mesh
      config.add_show_field :eds_subjects_genre
      config.add_show_field :eds_author_supplied_keywords
      config.add_show_field :eds_subset
      config.add_show_field :eds_code_naics
      config.add_show_field :eds_fulltext_word_count
      config.add_show_field :eds_covers
      config.add_show_field :eds_cover_thumb_url,      helper_method: :url_link
      config.add_show_field :eds_cover_medium_url,     helper_method: :url_link
      config.add_show_field :eds_images
      config.add_show_field :eds_quick_view_images
      config.add_show_field :eds_pdf_fulltext_available
      config.add_show_field :eds_ebook_pdf_fulltext_available
      config.add_show_field :eds_ebook_epub_fulltext_available
      config.add_show_field :eds_abstract_supplied_copyright
      config.add_show_field :eds_descriptors
      config.add_show_field :eds_publication_id
      config.add_show_field :eds_publication_is_searchable
      config.add_show_field :eds_publication_scope_note
      config.add_show_field :all_subjects_search_links
      config.add_show_field :eds_database_id
      config.add_show_field :eds_accession_number
      config.add_show_field :eds_database_name
      config.add_show_field :id
      config.add_show_field :eds_relevancy_score

      # === Search fields ===
      # "Fielded" search configuration. Used by pulldown among other places.
      # For supported keys in hash, see rdoc for Blacklight::SearchFields.
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # "All Fields" is intentionally placed last.

      # Remove the fields that were set by Config::Catalog.
      config.search_fields.clear

      config.add_search_field :title            # 'TI'
      config.add_search_field :author           # 'AU'
      config.add_search_field :subject          # 'SU'
      config.add_search_field :text             # 'TX' # TODO: testing; remove?
      config.add_search_field :abstract         # 'AB' # TODO: testing; remove?
      config.add_search_field :source           # 'SO' # TODO: testing; remove?
      config.add_search_field :issn             # 'IS' # TODO: testing; remove?
      config.add_search_field :isbn             # 'IB' # TODO: testing; remove?
      #config.add_search_field :descriptor      # 'DE' # TODO: testing; remove?
      #config.add_search_field :series          # 'SE' # TODO: testing; remove?
      #config.add_search_field :subject_heading # 'SH' # TODO: testing; remove?
      #config.add_search_field :keywords        # 'KW' # TODO: testing; remove?
      config.add_search_field :all_fields, default: true

      # === Sort fields ===
      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      # Remove the fields that were set by Config::Catalog.
      config.sort_fields.clear

      config.add_sort_field :relevance, sort: 'relevance'
      config.add_sort_field :newest,    sort: 'newest'
      config.add_sort_field :oldest,    sort: 'oldest'

      # === Blacklight behavior configuration ===

      # Force spell checking in all cases, no max results required.
      config.spell_max = 9999999999

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
      #config.default_more_limit = 15 # config.default_facet_limit # NOTE: was 20

      # Configuration for suggester.
      #config.autocomplete_enabled = true
      #config.autocomplete_path    = 'suggest'

      # === Blacklight Advanced Search ===

      #config.advanced_search ||= Blacklight::OpenStructWithHashAccess.new
      ##config.advanced_search.qt                  ||= 'search'
      #config.advanced_search.url_key              ||= 'advanced'
      #config.advanced_search.query_parser         ||= 'dismax'
      #config.advanced_search.form_solr_parameters ||= {}
=begin
      config.advanced_search.form_solr_parameters[:'facet.field'] = %i(
        eds_search_limiters_facet
        eds_publication_type_facet
        eds_publication_year_facet
        eds_category_facet
        eds_subject_topic_facet
        eds_language_facet
        eds_journal_facet
        eds_subjects_geographic_facet
        eds_publisher_facet
        eds_content_provider_facet
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
