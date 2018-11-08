# lib/ext/blacklight/lib/blacklight/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/configuration'

# Override Blacklight definitions.
#
# @see Blacklight::Configuration
#
module Blacklight::ConfigurationExt

  # document_model
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#document_model
  #
  def document_model
    fetch_value(__method__) || SolrDocument
  end

  # document_factory
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#document_factory
  #
  def document_factory
    fetch_value(__method__) || Blacklight::DocumentFactory
  end

  # response_model
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#response_model
  #
  def response_model
    fetch_value(__method__) || Blacklight::Solr::Response
  end

  # repository_class
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#repository_class
  #
  def repository_class
    fetch_value(__method__) || Blacklight::Solr::Repository
  end

  # connection_config
  #
  # @return [Hash]
  #
  # This method overrides:
  # @see Blacklight::Configuration#connection_config
  #
  def connection_config
    fetch_value(__method__) || Blacklight.connection_config
  end

  # search_builder_class
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#search_builder_class
  #
  def search_builder_class
    fetch_value(__method__) || locate_search_builder_class
  end

  # facet_paginator_class
  #
  # @return [Class]
  #
  # This method overrides:
  # @see Blacklight::Configuration#facet_paginator_class
  #
  def facet_paginator_class
    fetch_value(__method__) || Blacklight::Solr::FacetPaginator
  end

  # default_per_page
  #
  # @return [Numeric]
  #
  # This method overrides:
  # @see Blacklight::Configuration#default_per_page
  #
  def default_per_page
    fetch_value(__method__) || per_page.first
  end

  # default_search_field
  #
  # @return [Blacklight::Configuration::SearchField]
  #
  # This method overrides:
  # @see Blacklight::Configuration#default_search_field
  #
  def default_search_field
    fetch_value(__method__) ||
      search_fields.values.find { |f| f.default.is_a?(TrueClass) } ||
      search_fields.values.first
  end

  # default_sort_field
  #
  # @return [Blacklight::Configuration::SortField]
  #
  # This method overrides:
  # @see Blacklight::Configuration#default_sort_field
  #
  def default_sort_field
    fetch_value(__method__) ||
      sort_fields.values.find { |f| f.default.is_a?(TrueClass) } ||
      sort_fields.values.first
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Attempt to the value configured for a specific lens or configured
  # generally.
  #
  # @param [Symbol]
  #
  # @return [Object, nil]
  #
  def fetch_value(method)
    fetch(:lens, nil)&.fetch(method, nil) || fetch(method, nil)
  end

  # This block is not executed; it only exists to allow RubyMine to identify
  # methods that are created dynamically.
  unless ONLY_FOR_DOCUMENTATION

    # @return [Blacklight::OpenStructWithHashAccess]
    #
    # @see #default_values
    #
    def navbar(*) super end

    # @return [Blacklight::ViewConfig::Index]
    #
    # @see #default_values
    #
    def index(*) super end

    # @return [Blacklight::ViewConfig::Show]
    #
    # @see #default_values
    #
    def show(*) super end

    # @return [Blacklight::NestedOpenStructWithHashAccess]
    #
    # @see #default_values
    #
    def view(*) super end

    # @return [ActiveSupport::OrderedHash]
    #
    # @see #add_facet_field
    # @see #default_values
    #
    def facet_fields(*) super end

    # @return [ActiveSupport::OrderedHash]
    #
    # @see #add_index_field
    # @see #default_values
    #
    def index_fields(*) super end

    # @return [ActiveSupport::OrderedHash]
    #
    # @see #add_show_field
    # @see #default_values
    #
    def show_fields(*) super end

    # @return [ActiveSupport::OrderedHash]
    #
    # @see #add_search_field
    # @see #default_values
    #
    def search_fields(*) super end

    # @return [ActiveSupport::OrderedHash]
    #
    # @see #add_sort_field
    # @see #default_values
    #
    def sort_fields(*) super end

    # @return [Blacklight::Configuration::FacetField]
    #
    # @see #define_field_access
    # @see #add_blacklight_field
    # @see #facet_fields
    #
    def add_facet_field(*) super end

    # @return [Blacklight::Configuration::IndexField]
    #
    # @see #define_field_access
    # @see #add_blacklight_field
    # @see #index_fields
    #
    def add_index_field(*) super end

    # @return [Blacklight::Configuration::ShowField]
    #
    # @see #define_field_access
    # @see #add_blacklight_field
    # @see #show_fields
    #
    def add_show_field(*) super end

    # @return [Blacklight::Configuration::SearchField]
    #
    # @see #define_field_access
    # @see #add_blacklight_field
    # @see #search_fields
    #
    def add_search_field(*) super end

    # @return [Blacklight::Configuration::SortField]
    #
    # @see #define_field_access
    # @see #add_blacklight_field
    # @see #sort_fields
    #
    def add_sort_field(*) super end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Configuration => Blacklight::ConfigurationExt

__loading_end(__FILE__)
