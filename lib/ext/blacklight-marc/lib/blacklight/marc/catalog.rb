# lib/ext/blacklight-marc/lib/blacklight/marc/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/marc/catalog'

# Override Blacklight::Marc definitions.
#
# @see Blacklight::Marc::Catalog
#
module Blacklight::Marc::CatalogExt

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog overrides
  # ===========================================================================

  public

  # single_endnote_catalog_path
  #
  # @param [Hash, nil] opt
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#single_endnote_catalog_path
  #
  def single_endnote_catalog_path(opt = nil)
    endnote_document_path(opt)
  end

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog overrides
  # ===========================================================================

  private

  # render_librarian_view_control?
  #
  # @param [Blacklight::Configuration::Field] _config   Unused.
  # @param [Hash, nil]                        opt
  #
  # @option opt [String, Array<String>] :document
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#render_librarian_view_control?
  #
  def render_librarian_view_control?(_config = nil, opt = nil)
    opt&.fetch(:document, nil)&.has_marc?
  end

  # render_refworks_action?
  #
  # @param [Blacklight::Configuration::Field] _config   Unused.
  # @param [Hash, nil]                        opt
  #
  # @option opt [String, Array<String>] :document
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#render_refworks_action?
  #
  def render_refworks_action?(_config = nil, opt = nil)
    opt&.fetch(:document, nil)&.exports_as?(:refworks_marc_txt)
  end

  # render_endnote_action?
  #
  # @param [Blacklight::Configuration::Field] _config   Unused.
  # @param [Hash, nil]                        opt
  #
  # @option opt [String, Array<String>] :document
  #
  # This method overrides:
  # @see Blacklight::Marc::Catalog#render_endnote_action?
  #
  def render_endnote_action?(_config = nil, opt = nil)
    opt&.fetch(:document, nil)&.exports_as?(:endnote)
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Blacklight::Marc::Catalog => Blacklight::Marc::CatalogExt

__loading_end(__FILE__)
