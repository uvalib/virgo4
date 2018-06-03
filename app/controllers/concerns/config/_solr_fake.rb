# app/controllers/concerns/config/_solr_fake.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_common'

class Config::SolrFake

  # Default Blacklight Lens for controllers based on this configuration.
  SOLR_DEFAULT_LENS = :catalog

  # ===========================================================================
  # :section:
  # ===========================================================================

  # The Blacklight configuration for lenses using a local Solr service with
  # test data.
  #
  # @return [Blacklight::Configuration]
  #
  # @see Blacklight::Configuration#default_values
  #
  def self.instance
    # rubocop:disable Metrics/LineLength
    production_solr(false)
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
      config.index.display_type_field = :format
      config.index.title_field        = :title_display
      #config.index.thumbnail_field   = :thumbnail_path_ss

      # === Configuration for document/show views ===
      # @see Blacklight::Configuration::ViewConfig::Show

      config.show.document_presenter_class = Blacklight::ShowPresenterExt
      config.show.display_type_field  = :format
      config.show.title_field         = :title_display
      #config.show.thumbnail_field    = :thumbnail_path_ss
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

      config.add_facet_field :format,              label: 'Format'
      config.add_facet_field :pub_date,            label: 'Publication Year', single: true
      config.add_facet_field :subject_topic_facet, label: 'Topic',            limit:  20,   index_range: 'A'..'Z'
      config.add_facet_field :language_facet,      label: 'Language',         limit:  true
      config.add_facet_field :lc_1letter_facet,    label: 'Call Number'
      config.add_facet_field :subject_geo_facet,   label: 'Region'
      config.add_facet_field :subject_era_facet,   label: 'Era'

      config.add_facet_field :example_pivot_field, label: 'Pivot Field', pivot: %w(format language_facet)

      now = Time.zone.now.year
      config.add_facet_field :example_query_facet_field, label: 'Publish Date', query: {
        years_5:  { label: 'within 5 Years',  fq: "pub_date:[#{now-5}  TO *]" },
        years_10: { label: 'within 10 Years', fq: "pub_date:[#{now-10} TO *]" },
        years_25: { label: 'within 25 Years', fq: "pub_date:[#{now-25} TO *]" }
      }

      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # === Index (results page) metadata fields ===
      # Solr fields to be displayed in the index (search results) view.
      # (The ordering of the field names is the order of the display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] IndexPresenterExt#heading shows :title_display so it does not need
      #     to be included here.

      config.add_index_field :title_vern_display,     label: 'Title'
      config.add_index_field :author_display,         label: 'Author'
      config.add_index_field :author_vern_display,    label: 'Author'
      config.add_index_field :format,                 label: 'Format',            helper_method: :format_facet_label
      config.add_index_field :language_facet,         label: 'Language'
      config.add_index_field :published_display,      label: 'Published'
      config.add_index_field :published_vern_display, label: 'Published'
      config.add_index_field :lc_callnum_display,     label: 'Call number'

      # === Item details (show page) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access
      #
      # ==== Implementation Notes
      # [1] ShowPresenterExt#heading shows :title_display, :title_vern_display,
      #     :subtitle_display, :subtitle_vern_display, :author_display,, and
      #     :author_vern_display so they do not need to be included here.

      #config.add_show_field :title_display,           label: 'Title'
      #config.add_show_field :title_vern_display,      label: 'Title'
      #config.add_show_field :subtitle_display,        label: 'Subtitle'
      #config.add_show_field :subtitle_vern_display,   label: 'Subtitle'
      #config.add_show_field :author_display,          label: 'Author'
      #config.add_show_field :author_vern_display,     label: 'Author'
      config.add_show_field :format,                  label: 'Format'
      config.add_show_field :url_fulltext_display,    label: 'URL'
      config.add_show_field :url_suppl_display,       label: 'More Information'
      config.add_show_field :language_facet,          label: 'Language'
      config.add_show_field :published_display,       label: 'Published'
      config.add_show_field :published_vern_display,  label: 'Published'
      config.add_show_field :lc_callnum_display,      label: 'Call number'
      config.add_show_field :isbn_t,                  label: 'ISBN'

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
      # Now we see how to over-ride Solr request handler defaults, in this case
      # for a BL "search field", which is really a dismax aggregate of Solr
      # search fields.
      #
      # NOTE: "All Fields" is intentionally placed last.

      # "Title" search selection.
      config.add_search_field(:title) do |field|
        field.solr_local_parameters = {
          'spellcheck.dictionary': 'title',
          qf: '${title_qf}',
          pf: '${title_pf}'
        }
      end

      # "Author" search selection.
      config.add_search_field(:author) do |field|
        field.solr_local_parameters = {
          'spellcheck.dictionary': 'author',
          qf: '${author_qf}',
          pf: '${author_pf}'
        }
      end

      # "Subject" search selection.
      config.add_search_field(:subject) do |field|
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
      config.add_search_field :all_fields, label: 'All Fields', default: true

      # === Sort fields ===
      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      config.add_sort_field :relevance,  sort: 'score desc, pub_date_sort desc, title_sort asc', label: 'Relevance'
      config.add_sort_field :newest,     sort: 'pub_date_sort desc, title_sort    asc',          label: 'Date'
      config.add_sort_field :oldest,     sort: 'pub_date_sort desc, title_sort    desc',         label: 'Date (oldest first)'
      config.add_sort_field :title,      sort: 'title_sort    asc,  pub_date_sort desc',         label: 'Title'
      config.add_sort_field :title_rev,  sort: 'title_sort    desc, pub_date_sort desc',         label: 'Title (reverse)'
      config.add_sort_field :author,     sort: 'author_sort   asc,  title_sort    asc',          label: 'Author'
      config.add_sort_field :author_rev, sort: 'author_sort   desc, title_sort    asc',          label: 'Author (reverse)'

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
      config.default_more_limit = config.default_facet_limit # NOTE: was 20

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

    end
    # rubocop:enable Metrics/LineLength
  end

end

__loading_end(__FILE__)
