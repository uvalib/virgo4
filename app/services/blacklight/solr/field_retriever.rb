# app/services/blacklight/solr/field_retriever.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight/solr'
require_relative '../lens/field_retriever'

module Blacklight::Solr

  # Blacklight::Solr::FieldRetriever
  #
  # @see Blacklight::Lens::FieldRetriever
  #
  class FieldRetriever < Blacklight::Lens::FieldRetriever

    # =========================================================================
    # :section: Blacklight::FieldRetriever overrides
    # =========================================================================

    public

    # Retrieve the field values.
    #
    # Multi-valued fields (like :subject_a or :barcode_e) will be returned in
    # an array; single value fields (like :shelfkey or :fullrecord) will be
    # returned as a string.
    #
    # @return [Array, String, nil]
    #
    # This method overrides:
    # @see Blacklight::Lens::FieldRetriever#fetch
    #
    def fetch
      if raw
        values = Array.wrap(super)
        (field =~ /_[a-z]$/) ? values : values.first
      else
        super
      end
    end

  end

end

__loading_end(__FILE__)
