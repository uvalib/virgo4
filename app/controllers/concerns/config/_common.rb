# app/controllers/concerns/config/_common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Config

  # Config::Common
  #
  # Constants and methods for use within configuration blocks.
  #
  module Common

    include UVA::Constants

    # Options for displaying separator between metadata items with multiple
    # values.
    HTML_LINES = %i(
      words_connector
      two_words_connector
      last_word_connector
    ).map { |k| [k, ''] }.to_h.deep_freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

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
    # @return [Blacklight::Configuration]   The modified configuration.
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

      # === Index (results page) metadata fields ===

      # Set index field labels for this lens.
      config.index_fields.each_pair do |_, field|
        field.label = field.display_label(:index, lens_key)
      end

      # === Item details (show page) metadata fields ===

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

  end

end

__loading_end(__FILE__)
