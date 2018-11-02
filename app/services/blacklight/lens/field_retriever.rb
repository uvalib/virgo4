# app/services/blacklight/lens/field_retriever.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::FieldRetriever extends the Blacklight class to modify
  # processing of the field values (specifically to eliminate highlighting).
  #
  # @see Blacklight::FieldRetriever
  #
  class FieldRetriever < Blacklight::FieldRetriever

    include Blacklight::Lens

    # =========================================================================
    # :section: Blacklight::FieldRetriever overrides
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [LensDocument]                     document
    # @param [Blacklight::Configuration::Field] field_config
    # @param [Hash, nil]                        opt
    #
    # @option opt [Boolean] :raw      If *true*, only simple retrieval.
    #
    # @see Blacklight::SearchService#initialize
    #
    def initialize(document, field_config, opt = nil)
      super(document, field_config)
      @raw = opt&.fetch(:raw, false)
    end

    # Retrieve the field values.
    #
    # Multi-valued fields (like :subject_a or :barcode_e) will be returned in
    # an array; single value fields (like :shelfkey or :fullrecord) will be
    # returned as a string.
    #
    # @return [Array, String, nil]
    #
    def fetch
      if @raw
        values = Array.wrap(retrieve_simple)
        (field =~ /_[a-z]$/) ? values : values.first
      else
        super
      end
    end

  end

end

__loading_end(__FILE__)
