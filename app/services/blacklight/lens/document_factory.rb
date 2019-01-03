# app/services/blacklight/lens/document_factory.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::DocumentFactory
  #
  # Generates a document of the appropriate type.
  #
  # @see Blacklight::DocumentFactory
  #
  # == Implementation Notes
  # The base class assumes that the search service is based on Solr.
  #
  class DocumentFactory < Blacklight::DocumentFactory

    # =========================================================================
    # :section: Blacklight::DocumentFactory overrides
    # =========================================================================

    public

    # Translate the provided data into a document of the kind expected by the
    # current lens.
    #
    # If *data* is already a LensDocument (or a derived class) then it is
    # returned directly.
    #
    # @param [Object] data
    # @param [Object] response
    # @param [Hash]   opt
    #
    # @option opt [Symbol]                    :lens
    # @option opt [Blacklight::Configuration] :blacklight_config
    #
    # @return [LensDocument]
    #
    # This method overrides:
    # @see Blacklight::DocumentFactory#build
    #
    def self.build(data, response, opt)
      doc_type = document_model(data, opt)
      data.is_a?(doc_type) ? data : create(data, response, opt)
    end

    # Return the class for documents of the kind expected by the current lens.
    #
    # @param [Object] _data           Unused.
    # @param [Hash]   opt
    #
    # @option opt [Class] :document_model
    #
    # @return [Class] (SolrDocument)
    #
    # This method overrides:
    # @see Blacklight::DocumentFactory#document_model
    #
    def self.document_model(_data, opt)
      opt ||= {}
      opt[:document_model] || SolrDocument
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Translate the provided data into a document of the kind expected by the
    # current lens.
    #
    # @param [Object] data
    # @param [Object] response
    # @param [Hash]   opt
    #
    # @option opt [Symbol]                    :lens
    # @option opt [Blacklight::Configuration] :blacklight_config
    #
    # @return [LensDocument]
    #
    def self.create(data, response, opt)
      opt ||= {}
      lens = opt[:lens] || opt.dig(:blacklight_config, :lens_key)
      document_model(data, opt).new(data, response, lens)
    end

  end

end

__loading_end(__FILE__)
