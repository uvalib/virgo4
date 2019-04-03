# app/models/concerns/blacklight/lens/document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require_relative '../document/base'
require_relative 'document/export'
require_relative 'document/schema_org'
require_relative 'document/availability'

# Blacklight::Lens::Document
#
# @see Blacklight::Document
# @see Blacklight::Document::Base
#
module Blacklight::Lens::Document

  extend ActiveSupport::Concern

  include Blacklight::Lens
  include Blacklight::Document::ActiveModelShim
  include Blacklight::Document
  include Blacklight::Document::Base
  include Blacklight::Lens::Document::Export
  include Blacklight::Lens::Document::SchemaOrg
  include Blacklight::Lens::Document::Availability

  # For Blacklight::Gallery
  include Blacklight::Gallery::OpenseadragonSolrDocument

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, nil]                    source_doc
  # @param [RSolr::HashWithResponse, nil] response
  # @param [Symbol, nil]                  lens
  #
  # This method overrides:
  # @see Blacklight::Document::Base#initialize
  #
  def initialize(source_doc = nil, response = nil, lens = nil)
    @lens = lens
    raise if @lens && !@lens.is_a?(Symbol)
    Blacklight::Document::Base.register_export_formats(self)
    @raw_source ||= source_doc
    super(source_doc, response)
  end

  # ===========================================================================
  # :section: Blacklight::Document::Base overrides
  # ===========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and not
  # discoverable).
  #
  # This method overrides:
  # @see Blacklight::Document::Base#hidden?
  #
  def hidden?
    has?(:shadowed_location_f, 'HIDDEN')
  end

  # Indicate whether this document can be discovered by user search.
  #
  # This method overrides:
  # @see Blacklight::Document::Base#discoverable?
  #
  def discoverable?
    !has?(:shadowed_location_f, 'UNDISCOVERABLE')
  end

  # Indicate whether this document is a journal or other serial.
  #
  # This method overrides:
  # @see Blacklight::Document::Base#journal?
  #
  def journal?
    has?(:format_f, 'Journal/Magazine')
  end

  # Indicate whether this document represents an item that is accessible
  # through Patron Driven Acquisitions (PDA).
  #
  # This method overrides:
  # @see Blacklight::Document::Base#pda?
  #
  def pda?
    has_feature?('pda_print', 'pda_ebook')
  end

  # ===========================================================================
  # :section: Blacklight::Document::Base overrides
  # ===========================================================================

  public

  # Indicate whether this document has any of the named feature(s).
  #
  # @param [Array<String, Array<String>>] *
  #
  # @return [String]                  The first matching feature.
  # @return [nil]                     If none of *features* were found.
  #
  # This method overrides:
  # @see Blacklight::Document::Base#has_feature?
  #
  def has_feature?(*features)
    has?(:feature_f, *features)
  end

  # Physical item identifiers.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::Document::Base#barcodes
  #
  def barcodes(*)
    values(:barcode_f)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate the originating lens.
  #
  # @return [Symbol]
  #
  def lens
    @lens || Blacklight::Lens.default_lens_key
  end

  # Effectively "cast" the document to the given model type.
  #
  # @param [Symbol, String, Class] model  A LensDocument subclass type.
  #
  # @return [LensDocument]                An instance of the subclass type.
  #
  def as(model)
    key = Blacklight::Lens.key_for(model)
    unless model.respond_to?(:new)
      ctrlr = (key == :articles) ? ArticlesController : CatalogController
      model = ctrlr.blacklight_config.document_model
    end
    model.new(_source, response, key) rescue self
  end

  # The document ID to be used for external references
  #
  # @return [String]
  #
  def export_id
    id
  end

  # The original data received from the search repository.
  #
  # @return [String]
  #
  def raw_source
    @raw_source
  end

end

__loading_end(__FILE__)
