# lib/ext/blacklight-marc/lib/blacklight/marc/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Support for actively redefining objects defined in the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight/marc/catalog'

override Blacklight::Marc::Catalog do

  # ===========================================================================
  # :section: Blacklight::Marc::Catalog overrides
  # ===========================================================================

  public

  def single_endnote_catalog_path(options = nil)
    endnote_document_path(options)
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
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
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
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
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
  # @options opt [String, Array<String>] :document
  #
  # Compare with:
  # @see Blacklight::Marc::Catalog#render_endnote_action?
  #
  def render_endnote_action?(_config = nil, opt = nil)
    opt&.fetch(:document, nil)&.exports_as?(:endnote)
  end

end

__loading_end(__FILE__)
