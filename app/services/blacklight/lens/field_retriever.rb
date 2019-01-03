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
    # :section:
    # =========================================================================

    public

    # Indicates whether the field should be retrieved exactly as it was
    # provided by the search repository.
    #
    # @return [TrueClass, FalseClass]   Default: *false*
    #
    attr_reader :raw

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
    # This method overrides:
    # @see Blacklight::FieldRetriever#initialize
    #
    def initialize(document, field_config, opt = nil)
      super(document, field_config)
      @raw = opt&.fetch(:raw, false)
    end

    # Retrieve the field values.
    #
    # @return [Array, String, nil]
    #
    # This method overrides:
    # @see Blacklight::FieldRetriever#fetch
    #
    def fetch
      if raw
        field_config.accessor ? retieve_using_accessor : retrieve_simple
      else
        super
      end
    end

  end

end

__loading_end(__FILE__)
