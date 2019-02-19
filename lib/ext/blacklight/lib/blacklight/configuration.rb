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

  # ===========================================================================
  # :section: Blacklight::Configuration overrides
  # ===========================================================================

  public

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
  # :section: Local methods
  # ===========================================================================

  public

  # Indicate whether *name* is a sort key and/or is part of the Solr sort.
  #
  # @param [String, Symbol] name
  #
  def sort_field?(name)
    name = name.to_s
    sort_fields.any? { |k, v| (k.to_s == name) || v.sort.include?(name) }
  end

  # Indicate whether *name* is a facet field.
  #
  # @param [String, Symbol] name
  #
  def facet_field?(name)
    facet_fields.key?(name)
  end

  # Indicate whether *name* is an index field.
  #
  # @param [String, Symbol] name
  #
  def index_field?(name)
    index_fields.key?(name)
  end

  # Indicate whether *name* is a display field.
  #
  # @param [String, Symbol] name
  #
  def show_field?(name)
    show_fields.key?(name)
  end

  # ===========================================================================
  # :section: Local methods
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

    # Include a metadata facet field which can be used in queries to the search
    #  repository, and which may be displayed as a search limiter.
    #
    # This method is dynamically generated from the Blacklight::Configuration
    # class definition via `define_field_access :facet_field` as a "shortcut"
    # for `add_blacklight_field('facet_field',*)`.
    #
    # @return [Blacklight::Configuration::FacetField]
    #
    # @see #facet_fields
    # @see Blacklight::Configuration::FieldsExt#add_blacklight_field
    #
    def add_facet_field(*) super end

    # Include a metadata field to be retrieved and displayed for each document
    # entry in search results.
    #
    # This method is dynamically generated from the Blacklight::Configuration
    # class definition via `define_field_access :index_field` as a "shortcut"
    # for `add_blacklight_field('index_field',*)`.
    #
    # @return [Blacklight::Configuration::IndexField]
    #
    # @see #index_fields
    # @see Blacklight::Configuration::FieldsExt#add_blacklight_field
    #
    def add_index_field(*) super end

    # Include a metadata field to be retrieved and displayed for a document on
    # the item details show page.
    #
    # This method is dynamically generated from the Blacklight::Configuration
    # class definition via `define_field_access :show_field` as a "shortcut"
    # for `add_blacklight_field('show_field',*)`.
    #
    # @return [Blacklight::Configuration::ShowField]
    #
    # @see #show_fields
    # @see Blacklight::Configuration::FieldsExt#add_blacklight_field
    #
    def add_show_field(*) super end

    # Include a metadata search field which is supported by the search
    # repository as a specific kind of search type, and which may be displayed
    # as a selection in the search type dropdown menu adjacent to the search
    # term input.
    #
    # This method is dynamically generated from the Blacklight::Configuration
    # class definition via `define_field_access :search_field` as a "shortcut"
    # for `add_blacklight_field('search_field',*)`.
    #
    # @return [Blacklight::Configuration::SearchField]
    #
    # @see #search_fields
    # @see Blacklight::Configuration::FieldsExt#add_blacklight_field
    #
    def add_search_field(*) super end

    # Include a metadata search field which is supported by the search
    # repository to return results in a specified order, and which may be
    # displayed as a selection in the sort dropdown menu on each search results
    # index page.
    #
    # This method is dynamically generated from the Blacklight::Configuration
    # class definition via `define_field_access :sort_field` as a "shortcut"
    # for `add_blacklight_field('sort_field',*)`.
    #
    # @return [Blacklight::Configuration::SortField]
    #
    # @see #sort_fields
    # @see Blacklight::Configuration::FieldsExt#add_blacklight_field
    #
    def add_sort_field(*) super end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Configuration => Blacklight::ConfigurationExt

__loading_end(__FILE__)
