# lib/ext/blacklight/lib/blacklight/configuration.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/configuration'

override Blacklight::Configuration do

  # @return [Class]
  def document_model
    fetch_value(__method__) || SolrDocument
  end

  # @return [Class]
  def document_factory
    fetch_value(__method__) || Blacklight::DocumentFactory
  end

  # @return [Class]
  def response_model
    fetch_value(__method__) || Blacklight::Solr::Response
  end

  # @return [Class]
  def repository_class
    fetch_value(__method__) || Blacklight::Solr::Repository
  end

  # @return [Hash]
  def connection_config
    fetch_value(__method__) || Blacklight.connection_config
  end

  # @return [Class]
  def search_builder_class
    fetch_value(__method__) || locate_search_builder_class
  end

  # @return [Class]
  def facet_paginator_class
    fetch_value(__method__) || Blacklight::Solr::FacetPaginator
  end

  # @return [Numeric]
  def default_per_page
    fetch_value(__method__) || per_page.first
  end

  # @return [Blacklight::Configuration::SearchField]
  def default_search_field
    fetch_value(__method__) ||
      search_fields.values.find { |f| f.default.is_a?(TrueClass) } ||
      search_fields.values.first
  end

  # @return [Blacklight::Configuration::SortField]
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

    # @see #default_values
    # @return [Blacklight::OpenStructWithHashAccess]
    def navbar(*) super end

    # @see #default_values
    # @return [Blacklight::ViewConfig::Index]
    def index(*) super end

    # @see #default_values
    # @return [Blacklight::ViewConfig::Show]
    def show(*) super end

    # @see #default_values
    # @return [Blacklight::NestedOpenStructWithHashAccess]
    def view(*) super end

    # @see #default_values
    # @return [ActiveSupport::OrderedHash]
    def facet_fields(*) super end

    # @see #default_values
    # @return [ActiveSupport::OrderedHash]
    def index_fields(*) super end

    # @see #default_values
    # @return [ActiveSupport::OrderedHash]
    def show_fields(*) super end

    # @see #default_values
    # @return [ActiveSupport::OrderedHash]
    def search_fields(*) super end

    # @see #default_values
    # @return [ActiveSupport::OrderedHash]
    def sort_fields(*) super end

    # @see #define_field_access
    # @see #add_blacklight_field
    # @return [Blacklight::Configuration::FacetField]
    def add_facet_field(*) super end

    # @see #define_field_access
    # @see #add_blacklight_field
    # @return [Blacklight::Configuration::IndexField]
    def add_index_field(*) super end

    # @see #define_field_access
    # @see #add_blacklight_field
    # @return [Blacklight::Configuration::ShowField]
    def add_show_field(*) super end

    # @see #define_field_access
    # @see #add_blacklight_field
    # @return [Blacklight::Configuration::SearchField]
    def add_search_field(*) super end

    # @see #define_field_access
    # @see #add_blacklight_field
    # @return [Blacklight::Configuration::SortField]
    def add_sort_field(*) super end

  end

end

__loading_end(__FILE__)
