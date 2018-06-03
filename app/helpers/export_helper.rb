# app/helpers/export_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Shared definitions for exports.
#
# Compare with:
# @see BlacklightMarcHelper
#
module ExportHelper

  include BlacklightHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  REFWORKS_URL = 'https://www.refworks.com/express/expressimport.asp'

  # ===========================================================================
  # :section: BlacklightMarcHelper overrides
  # ===========================================================================

  public

  # refworks_export_url
  #
  # @param [Hash] url_params
  #
  # @options url_params [String] :url       Required path to document.
  # @options url_params [String] :vendor    Default: `application_name`.
  # @options url_params [String] :filter    Default: 'RefWorks Tagged Format'
  #
  # @return [String]
  #
  # Compare with:
  # @see BlacklightMarcHelper#refworks_export_url
  #
  def refworks_export_url(url_params = nil)
    opt = { vendor: application_name, filter: 'RefWorks Tagged Format' }
    case url_params
      when Hash   then opt.merge!(url_params)
      when String then opt[:url] = url_params
    end
    url_params = opt.map { |k, v| "#{k}=" + CGI.escape(v.to_s) }.join('&')
    "#{REFWORKS_URL}?#{url_params}"
  end

  # refworks_solr_document_path
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  # Compare with:
  # @see BlacklightMarcHelper#refworks_solr_document_path
  #
  def refworks_solr_document_path(options = nil)
    refworks_document_path(options)
  end

  # For exporting a single document in EndNote format.
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  # Compare with:
  # @see BlacklightMarcHelper#single_endnote_catalog_path
  #
  def single_endnote_catalog_path(options = nil)
    endnote_document_path(options)
  end

  # Combines a set of document references into one RefWorks export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # Compare with:
  # @see BlacklightMarcHelper#render_refworks_texts
  #
  def render_refworks_texts(documents)
    documents.map { |doc|
      doc.export_as(:refworks_marc_txt) if doc.exports_as?(:refworks_marc_txt)
    }.compact.join("\n")
  end

  # Combines a set of document references into one EndNote export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # Compare with:
  # @see BlacklightMarcHelper#render_endnote_texts
  #
  def render_endnote_texts(documents)
    documents.map { |doc|
      doc.export_as(:endnote) if doc.exports_as?(:endnote)
    }.compact.join("\n")
  end

  # Combines a set of document references into one Zotero RIS export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # @see BlacklightMarcHelper#render_refworks_texts
  # @see BlacklightMarcHelper#render_endnote_texts
  #
  def render_ris_texts(documents)
    documents.map { |doc|
      doc.export_as(:ris) if doc.exports_as?(:ris)
    }.compact.join("\n")
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # refworks_document_path
  #
  # @param [Hash] args
  #
  # @options args [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def refworks_document_path(*args)
    opt = { action: 'show', format: :refworks_marc_txt, only_path: false }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.present?
    return unless opt[:id].present?
    opt[:controller] ||= current_lens_key
    refworks_export_url(url_for(opt))
  end

  # For exporting a single document in EndNote format.
  #
  # @param [Hash] args
  #
  # @options args [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def endnote_document_path(*args)
    opt = { action: 'show', format: :endnote, only_path: true }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.present?
    return unless opt[:id].present?
    opt[:controller] ||= current_lens_key
    url_for(opt)
  end

  # For exporting a single document in Zotero RIS format.
  #
  # @param [Hash] args
  #
  # @options args [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  def ris_document_path(*args)
    opt = { action: 'show', format: :ris, only_path: true }
    opt.merge!(args.pop) if args.last.is_a?(Hash)
    opt[:id] = args.first if args.first.is_a?(String)
    return unless opt[:id].present?
    opt[:controller] ||= current_lens_key
    url_for(opt)
  end

end

__loading_end(__FILE__)
