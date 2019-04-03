# app/models/concerns/blacklight/document/base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Blacklight::Document

  # Blacklight::Document::Base is intended to be included after
  # Blacklight::Document in order to define extensions and replacement methods
  # to define "baseline" document behaviors.
  #
  module Base

    include Blacklight::Lens::Export

    # =========================================================================
    # :section: Blacklight::Document overrides
    # =========================================================================

    public

    # Helper method to check if value/multi-values exist for a given key.
    # The value can be a string, or a RegExp
    # Multiple "values" can be given; only one needs to match.
    #
    # @param [Symbol, String, Array<String,Symbol>] key
    # @param [Array<String,Regexp>]                 patterns
    #
    # This method overrides:
    # @see Blacklight::Document#has?
    #
    # == Implementation Notes
    # The original does not support the ability to test for the presence of any
    # key from an array of keys unless values are given.
    #
    def has?(key, *patterns)
      if key.is_a?(Array)
        key.any? { |k| has?(k, *patterns) }
      elsif !key?(key)
        false
      elsif (doc_values = Array.wrap(self[key]).reject(&:blank?)).blank?
        false
      elsif patterns.blank?
        true
      else
        patterns.any? do |expected|
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
    # @yield [Blacklight::Document] self
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

    # Get the first (or only) value of an index field.
    #
    # @param [String, Symbol] key
    #
    # This method overrides:
    # @see Blacklight::Document#first
    #
    def first(key)
      values(key).first
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get the value(s) of an index field as an array.
    #
    # @param [String, Symbol] key
    #
    # @return [Array<String>]
    #
    def values(key)
      Array.wrap(self[key]).compact
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether this document is shadowed (that is, not viewable and not
    # discoverable).
    #
    # By default, this method returns *false*; derived classes should override
    # as required.
    #
    def hidden?(*)
      false
    end

    # Indicate whether this document can be discovered by user search.
    #
    # Such records, even if not independently discoverable can be linked to and
    # accessed directly.  This is useful in the case of records that are
    # "part of" a discoverable collection.
    #
    # By default, this method returns *true*; derived classes should override
    # as required.
    #
    def discoverable?(*)
      true
    end

    # Indicate whether this document is a journal or other serial.
    #
    def journal?(*)
    end

    # Indicate whether this document represents an item that is accessible
    # through Patron Driven Acquisitions (PDA).
    #
    def pda?(*)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether this document has any of the named feature(s).
    #
    # @param [Array<String, Array<String>>] *
    #
    # @return [String]                The first matching feature.
    # @return [nil]                   If none of *features* were found.
    #
    def has_feature?(*)
    end

    # Physical item identifiers.
    #
    # @return [Array<String>]
    #
    def barcodes(*)
      []
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether this is a de-spined item.
    #
    # @param [String] *
    #
    def despined?(*)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # We will always support these export formats (unlike basic Blacklight
    # which only supports them for MARC-based metadata).
    #
    # @param [Blacklight::Document] doc
    #
    # @return [void]
    #
    def self.register_export_formats(doc)
      Blacklight::Lens::Export.mime_types.each_pair do |format, mime_type|
        doc.will_export_as(format.to_sym, mime_type)
      end
    end

  end

end

__loading_end(__FILE__)
