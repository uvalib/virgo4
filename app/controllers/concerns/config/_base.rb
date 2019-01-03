# app/controllers/concerns/config/_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Namespace for lens configuration classes.
#
module Config
end

# Base class for lens configuration classes.
#
class Config::Base

  include UVA::Constants

  # Options for displaying separator between metadata items with multiple
  # values.
  HTML_LINES = %i(
    words_connector
    two_words_connector
    last_word_connector
  ).map { |k| [k, HTML_NEW_LINE] }.to_h.deep_freeze

=begin # NOTE: old fields for reference - to be removed
  SEMANTIC_FIELDS = {
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  module ClassMethods

    # The lens key for the configuration class.
    #
    # @return [Symbol]
    #
    attr_accessor :key

    # The Blacklight configuration associated with the configuration class.
    #
    # @return [Blacklight::Configuration]
    #
    def blacklight_config
      Blacklight::Lens[@key].blacklight_config
    end

    # Make a deep copy of the Blacklight configuration.
    #
    # @param [Blacklight::Controller] other_controller
    #
    # @return [Blacklight::Configuration]
    #
    def deep_copy(other_controller)
      blacklight_config.inheritable_copy(other_controller)
    end

    # Set the lens key associated with the configuration class.
    #
    # @param [Symbol] lens_key
    #
    # @return [Symbol]
    #
    def key=(lens_key)
      Log.error(__method__, lens_key.inspect, 'was', @key.inspect) if @key
      @key = lens_key
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def build_configuration(controller)
      Blacklight::Configuration.new do |config|
        configure!(config, controller)
      end
    end

    # Configuration options that are applicable to all lenses.
    #
    # This is the first call made from the #configure! class method of the
    # derived class.
    #
    # @param [Blacklight::Configuration]     config
    # @param [Blacklight::Controller, Class] controller
    #
    # @return [Blacklight::Configuration]   The modified configuration.
    #
    def configure!(config, controller)

      config.klass = controller.is_a?(Class) ? controller : controller.class

      # =======================================================================
      # Lens
      # =======================================================================

      # Default Blacklight Lens for controllers based on this configuration.
      # NOTE: The derived class must set config.lens_key.

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

      # NOTE: The derived class must call response_models!().

      # =======================================================================
      # Views
      # =======================================================================

      # === Configurations for specific types of index views ===
      # @see Blacklight::Configuration#view_config

      # config.view =
      #   Blacklight::NestedOpenStructWithHashAccess.new(
      #     Blacklight::Configuration::ViewConfig,
      #     'list',
      #     atom: { if: false, partials: [:document] },
      #     rss:  { if: false, partials: [:document] },
      #   )

      # =======================================================================
      # Facets
      # =======================================================================

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

      # NOTE: Facet metadata fields must be defined in the derived class.

      # =======================================================================
      # Index pages (search results)
      # =======================================================================

      # === Configuration for search results/index views ===
      # @see Blacklight::Configuration::ViewConfig::Index

      config.index.partials = %i(index_header thumbnail index)

      # === Index metadata fields ===
      # Solr fields to be displayed in the index (search results) view.
      # (The ordering of the field names is the order of the display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      # NOTE: Index metadata fields must be defined in the derived class.

      # =======================================================================
      # Show pages (item details)
      # =======================================================================

      # === Configuration for document/show views ===
      # @see Blacklight::Configuration::ViewConfig::Show

      config.show.partials = %i(show_header thumbnail show)

      # === Show page (item details) metadata fields ===
      # Solr fields to be displayed in the show (single result) view.
      # (The ordering of the field names is the order of display.)
      #
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      # NOTE: Show metadata fields must be defined in the derived class.

      # =======================================================================
      # Search fields
      # =======================================================================

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

      # NOTE: Search fields must be defined in the derived class.

      # =======================================================================
      # Sort fields
      # =======================================================================

      # "Sort results by" select (pulldown)
      # @see Blacklight::Configuration::Files::ClassMethods#define_field_access

      # NOTE: Sort fields must be defined in the derived class.

      # =======================================================================
      # Search parameters
      # =======================================================================

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
      config.autocomplete_enabled   = true
      config.autocomplete_path      = 'suggest'
      config.autocomplete_suggester = 'mySuggester'

      # =======================================================================
      # Blacklight Advanced Search
      # =======================================================================

      as = {
        qt:                   'search',
        url_key:              'advanced',
        query_parser:         'dismax',
        form_solr_parameters: {}
      }
      if config.advanced_search
        config.advanced_search.deep_merge!(as)
      else
        config.advanced_search = Blacklight::OpenStructWithHashAccess.new(as)
      end
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

      config
    end

    # Define per-repository response model values and copy them to the top
    # level of the configuration where Blacklight expects to see them.
    #
    # @param [Blacklight::Configuration]                       config
    # @param [Hash, Blacklight::OpenStructWithHashAccess, nil] added_values
    #
    # @return [void]
    #
    # == Configuration Fields
    # :connection_config
    #   For the standard catalog this is based on blacklight.yml; for alternate
    #   lenses this might allow for an alternate Solr to be accessed by
    #   providing an alternate blacklight.yml.
    #
    # :repository_class
    #   Class for sending and receiving requests from a search index.
    #
    # :search_builder_class
    #   Class for converting Blacklight's URL parameters into request
    #   parameters for the search index via repository_class.
    #
    # :response_model
    #   Model that maps search index responses to Blacklight responses.
    #
    # :document_model
    #   The model to use for each response document.
    #
    # :document_factory
    #   A class that builds documents.
    #
    # :facet_paginator_class
    #   Class for paginating long lists of facet fields.
    #
    # :thumbnail_presenter_class
    #   Class for displaying thumbnails.
    #
    def response_models!(config, added_values = nil)
      values =
        Blacklight::OpenStructWithHashAccess.new(

          connection_config:          nil,
          document_factory:           Blacklight::Lens::DocumentFactory,
          document_model:             LensDocument,
          facet_paginator_class:      Blacklight::Solr::FacetPaginator,
          field_presenter_class:      Blacklight::Lens::FieldPresenter,
          field_retriever_class:      Blacklight::Lens::FieldRetriever,
          repository_class:           Blacklight::Lens::Repository,
          response_model:             Blacklight::Lens::Response,
          search_builder_class:       SearchBuilder,
          thumbnail_presenter_class:  Blacklight::Lens::ThumbnailPresenter,

          index:
            Blacklight::Configuration::ViewConfig::Index.new(
              document_presenter_class: Blacklight::Lens::IndexPresenter
            ),

          show:
            Blacklight::Configuration::ViewConfig::Show.new(
              document_presenter_class: Blacklight::Lens::ShowPresenter
            ),
        )
      values.deep_merge!(added_values) if added_values.present?
      config.lens = values
      config.lens.each_pair do |field, value|
        struct_field =
          case field
            when :navbar
              config.navbar ||=
                OpenStructWithHashAccess.new
            when :index
              config.index ||=
                Blacklight::Configuration::ViewConfig::Index.new
            when :show
              config.show ||=
                Blacklight::Configuration::ViewConfig::Show.new
            when :view
              config.view ||=
                Blacklight::NestedOpenStructWithHashAccess.new(
                  Blacklight::Configuration::ViewConfig
                )
          end
        if struct_field
          value.each_pair { |k, v| struct_field[k] = v }
        else
          config[field] = value
        end
      end
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
      config.search_builder_processors ||= []
      config.search_builder_processors += values.flatten.compact.uniq
    end

    # Set mappings of configuration key to repository field for both :index and
    # :show configurations.
    #
    # @param [Blacklight::Configuration]                  config
    # @param [Hash, Blacklight::OpenStructWithHashAccess] values
    #
    # @return [void]
    #
    # == Mappings
    #
    # :display_type_field
    # :title_field
    # :subtitle_field
    # :alt_title_field
    # :author_field
    # :alt_author_field
    # :thumbnail_field
    #
    def semantic_fields!(config, values)
      values.each_pair do |key, value|
        config.show ||= Blacklight::Configuration::ViewConfig::Show.new
        config.show[key] = value
        config.index ||= Blacklight::Configuration::ViewConfig::Index.new
        config.index[key] = value
      end
    end

    # Add tools to the configuration.
    #
    # This method allows each repository-specific configuration to insert a
    # consistent set of definitions for tools and their setup.
    #
    # Certain show tools cause methods to be inserted into the controller via
    # ActionBuilder.  Tools that include the `define_method: false` option must
    # be defined manually.
    #
    # @param [Blacklight::Configuration] config
    #
    # @return [void]
    #
    # @see Blacklight::ActionBuilder#build
    #
    def add_tools!(config)
      # rubocop:disable Metrics/LineLength

      config.add_nav_action :bookmark,                partial: 'blacklight/nav/bookmark',                                 if: :render_bookmarks_control?
      config.add_nav_action :saved_searches,          partial: 'blacklight/nav/saved_searches',                           if: :render_saved_searches?
      config.add_nav_action :search_history,          partial: 'blacklight/nav/search_history',                           if: :render_search_history?

      config.add_show_tools_partial :bookmark,        partial: 'bookmark_control',                                        if: :render_bookmark_action?
      config.add_show_tools_partial :email,           callback: :email_action, validator: :validate_email_params,         if: :render_email_action?
      config.add_show_tools_partial :sms,             callback: :sms_action,   validator: :validate_sms_params,           if: :render_sms_action?
      config.add_show_tools_partial :citation,                                                                            if: :render_citation_action?
      config.add_show_tools_partial :librarian_view,                                               define_method: false,  if: :render_librarian_view_control?
      config.add_show_tools_partial :refworks,        modal: false, path: :refworks_solr_document_path, define_method: false,  if: :render_refworks_action?
      config.add_show_tools_partial :endnote,         modal: false,                                define_method: false,  if: :render_endnote_action?
      config.add_show_tools_partial :zotero,          modal: false,                                define_method: false,  if: :render_zotero_action?

      config.add_results_document_tool :bookmark,     partial: 'bookmark_control',                                        if: :render_bookmarks_control?

      config.add_results_collection_tool :sort_widget,                                                                    if: :render_sort_widget?
      config.add_results_collection_tool :per_page_widget,                                                                if: :render_per_page_widget?
      config.add_results_collection_tool :view_type_group,                                                                if: :render_view_type_group?

      # rubocop:enable Metrics/LineLength
    end

    # Add configuration for Blacklight::Gallery
    #
    # @param [Blacklight::Configuration] config
    #
    # @return [void]
    #
    def blacklight_gallery!(config)
      config.view.list.partials    = config.index.partials
      config.view.gallery.partials = %i(index_header index_details)
      config.view.masonry.partials = %i(index_details)
    end

    # Get field labels from I18n, including labels specific to this lens and
    # perform any updates that are appropriate for all fields of a given type
    # regardless of the lens.
    #
    # @param [Blacklight::Configuration] config
    #
    # @return [Blacklight::Configuration]   The modified configuration.
    #
    def finalize_configuration!(config)

      lens_key = config.lens_key

      # === Facet fields ===

      # Set facet field labels for this lens.
      config.facet_fields.each_pair do |_, field|
        field.label = field.display_label(:facet, lens_key)
      end

      # Have Blacklight send all facet field names to Solr.
      # (Remove to use Solr request handler defaults or to have no facets.)
      config.add_facet_fields_to_solr_request!

      # === Index metadata fields ===

      # Set index field labels for this lens.
      config.index_fields.each_pair do |_, field|
        field.label = field.display_label(:index, lens_key)
        #field.separator_options ||= HTML_LINES
      end

      # === Show page (item details) metadata fields ===

      # Set show field labels for this lens and supply options that apply to
      # multiple field configurations.
      config.show_fields.each_pair do |_, field|
        field.label = field.display_label(:show, lens_key)
        field.separator_options ||= HTML_LINES
      end

      # === Search fields ===

      # Set search field labels for this lens.
      config.search_fields.each_pair do |_, field|
        field.label = field.display_label(:search, lens_key)
      end

      # === Sort fields ===

      # Set sort field labels for this lens.
      config.sort_fields.each_pair do |_, field|
        field.label = field.display_label(:sort, lens_key)
      end

      config

    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Add facet fields to a configuration.
    #
    # @param [Blacklight::Configuration] config
    # @param [Array<String>]             names
    #
    # @return [void]
    #
    def add_facets!(config, *names)
      names.flatten.each do |type|
        name = type.end_with?('_f') ? type : "#{type}_f"
        config.add_facet_field(name) unless config.facet_field?(name)
      end
    end

    # Remove facet fields from a configuration.
    #
    # @param [Blacklight::Configuration] config
    # @param [Array<String>]             names
    #
    # @return [void]
    #
    # == Usage Notes
    # The baseline configuration for a repository (Config::Eds, Config::Solr)
    # contains all possible fields, however individual lenses will want to
    # limit the facets that are displayed.  This method provides a convenient
    # way to do that.
    #
    # == Development Notes
    # At this point there isn't a clear need for limiting the display of other
    # received repository information (e.g., eliminating display of certain
    # show page fields in item details), but that may change.
    #
    def remove_facets!(config, *names)
      names = names.flatten.map { |t| t.end_with?('_f') ? t : "#{t}_f" }
      config.facet_fields.extract!(*names)
    end

  end

  include ClassMethods
  extend  ClassMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new Config::Base-derivative instance by adding its
  # Blacklight::Configuration to the Blacklight::Lens table.
  #
  # @param [::Config::Base, Blacklight::Configuration] cfg
  #
  def initialize(cfg)
    cfg  = cfg.blacklight_config if cfg.respond_to?(:blacklight_config)
    @blacklight_config = cfg
    @key = cfg.lens_key
    self.class.key ||= @key
    Blacklight::Lens.add_new(@key, cfg)
  end

  # Generate a log message if the configured Solr is not appropriate.
  #
  # @params [TrueClass, FalseClass] required
  #
  # @return [true]                  If the right Solr is configured.
  # @return [false]                 Otherwise
  #
  def production_solr(required)
    prod = Blacklight.connection_config[:url].include?(PRODUCTION_SUBNET)
    return true if required == prod
    Log.error {
      "#{name}: This configuration will not work without changing " \
        'config/blacklight.yml'
    }
  end

  # The Blacklight configuration held by this instance.
  #
  # @return [Blacklight::Configuration]
  #
  attr_reader :blacklight_config

  delegate_missing_to(:blacklight_config)

end

__loading_end(__FILE__)
