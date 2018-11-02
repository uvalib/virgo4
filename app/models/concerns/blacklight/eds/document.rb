# app/models/concerns/blacklight/eds/document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require_relative '../lens/document'
require_relative 'document/export'
require_relative 'document/schema_org'

# Blacklight::Eds::Document
#
# == Implementation Notes
# Blacklight::Document::ActiveModelShim#to_partial_path is not overridden here
# because the partial 'articles/document' is not currently defined -- all
# document types are using 'app/views/catalog/_document.html.erb'.
#
# @see Blacklight::Lens::Document
#
module Blacklight::Eds::Document

  extend ActiveSupport::Concern

  include Blacklight::Lens::Document
  include Blacklight::Eds::Document::Export
  include Blacklight::Eds::Document::SchemaOrg
  extend  Blacklight::Eds::Document::SchemaOrg

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Document::Email      unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::Sms        unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::DublinCore unless ONLY_FOR_DOCUMENTATION

  # ===========================================================================
  # :section: Blacklight::Document::ActiveModelShim overrides
  # ===========================================================================

  public

  # Unique ID for the document.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ActiveModelShim#id
  #
  def id
    super.to_s.tr('.', '_')
  end

  # ===========================================================================
  # :section: Blacklight::Lens::Document overrides
  # ===========================================================================

  public

  # Indicate the originating lens.
  #
  # @return [Symbol]
  #
  def lens
    @lens || :articles
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  EDS_ID_KEYS   ||= %i(id eds_database_id eds_accession_number).freeze
  EDS_DOI_KEYS  ||= %i(eds_document_doi).freeze
  EDS_HTML_KEYS ||= %i(
    eds_abstract_supplied_copyright
    eds_authors_composed
    eds_author_affiliations
    eds_author_supplied_keywords
    eds_composed_title
    eds_subjects
  ).freeze

  # Adjust certain EBSCO field values before passing the data to the base
  # initializer.
  #
  # @param [Hash] data
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  #
  def prepare(data)
    data = ActiveSupport::HashWithIndifferentAccess.new(data || {})

    # Adjust EDS item identifiers so that they can be used with Rails paths.
    # (E.g., "/articles/db__idbase.part2" would appear to Rails as ID
    # "db__idbase" with format "part2" -- translating the dots prevents Rails
    # from interpreting it this way.)
    EDS_ID_KEYS.each do |k|
      data[k] &&= data[k].to_s.tr('.', '_')
    end

    # Normalize DOIs as the canonical URL path (regardless of how the publisher
    # supplied the DOI value).
    EDS_DOI_KEYS.each do |k|
      data[k] &&=
        URI.parse(URI.escape(data[k].to_s)).tap { |uri|
          uri.scheme = 'https'
          uri.host   = 'doi.org'
          uri.path   = '/' + uri.path unless uri.path.start_with?('/')
        }.to_s
    end

    # Allow the "composed title" to go through so that <searchLink> can
    # be styled as desired by CSS.
    EDS_HTML_KEYS.each do |k|
      data[k] = html_safe(data[k])
    end

    data
  end

  # Recursively make strings HTML-safe.
  #
  # @param [Object] item
  #
  # @return [Object]
  #
  def html_safe(item)
    case item
      when String
        item.html_safe
      when Array
        item.map! { |v| html_safe(v) }
      when Hash
        item.map { |k, v| [k, html_safe(v)] }.to_h.with_indifferent_access
      else
        item
    end
  end

end

__loading_end(__FILE__)
