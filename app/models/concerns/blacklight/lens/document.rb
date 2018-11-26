# app/models/concerns/blacklight/lens/document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require_relative '../document/base'
require_relative 'document/export'
require_relative 'document/schema_org'

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
    has?(:shadowed_location_facet, 'HIDDEN')
  end

  # Indicate whether this document can be discovered by user search.
  #
  # This method overrides:
  # @see Blacklight::Document::Base#discoverable?
  #
  def discoverable?
    !has?(:shadowed_location_facet, 'UNDISCOVERABLE')
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

end

__loading_end(__FILE__)
