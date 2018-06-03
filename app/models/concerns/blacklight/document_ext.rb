# app/models/concerns/blacklight/document_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::DocumentExt
#
# @see Blacklight::Document
#
module Blacklight::DocumentExt

  extend ActiveSupport::Concern

  include Blacklight::Document
  include Blacklight::Document::ExportExt
  include Blacklight::Document::SchemaOrgExt

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  public

  # Initialize a self instance
  #
  # @param [Hash, nil]                    source_doc
  # @param [RSolr::HashWithResponse, nil] response
  #
  # This method overrides:
  # @see Blacklight::Document#initialize
  #
  def initialize(source_doc = {}, response = nil)

    # Invoke Blacklight::Document initializer.
    source_doc ||= {}
    super(source_doc, response)

    # We will always support these export formats (unlike basic Blacklight
    # which only supports them for MARC-based metadata).
    will_export_as(:openurl_ctx_kev,   'application/x-openurl-ctx-kev')
    will_export_as(:refworks_marc_txt, 'text/plain')
    will_export_as(:endnote,           'application/x-endnote-refer')
    will_export_as(:ris,               'application/x-research-info-systems')

  end

  # Helper method to check if value/multi-values exist for a given key.
  # The value can be a string, or a RegExp
  # Multiple "values" can be given; only one needs to match.
  #
  # @param [Symbol, String, Array<String,Symbol>] key
  # @param [Array<String,Regexp>]                 values
  #
  # This method overrides:
  # @see Blacklight::Document#has?
  #
  # == Implementation Notes
  # The original does not support the ability to test for the presence of any
  # key from an array of keys unless values are given.
  #
  def has?(key, *values)
    if key.is_a?(Array)
      key.any? { |k| has?(k, *values) }
    elsif !key?(key)
      false
    elsif (doc_values = Array.wrap(self[key])).blank?
      false
    elsif values.blank?
      true
    else
      values.any? do |expected|
        if expected.is_a?(Regexp)
          doc_values.any? { |actual| actual =~ expected }
        else
          doc_values.any? { |actual| actual == expected }
        end
      end
    end
  end

  # Get an index field value contained in the document.
  #
  # @param [String, Symbol] key
  # @param [Array]          default
  #
  # @yield [Blacklight::DocumentExt] self
  #
  # @return [Array<String>, String, default.first]
  #
  # This method overrides:
  # @see Blacklight::Document#fetch
  #
  def fetch(key, *default)
    result =
      if key?(key)
        self[key]
      elsif block_given?
        yield(self)
      end
    unless result
      raise KeyError, "key not found \"#{key}\"" if default.empty?
      result = default.first
    end
    result
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and
  # not discoverable).
  #
  # By default, this method returns *false*; derived classes should override as
  # required.
  #
  def hidden?(*)
  end

  # Indicate whether this document can be discovered by user search.
  #
  # Such records, even if not independently discoverable can be linked to and
  # accessed directly.  This is useful in the case of records that are
  # "part of" a discoverable collection.
  #
  # By default, this method returns *true*; derived classes should override as
  # required.
  #
  def discoverable?(*)
    true
  end

end

__loading_end(__FILE__)
