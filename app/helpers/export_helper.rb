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

  include BlacklightMarcHelper
  include LensHelper
  include Blacklight::Lens::Export

  def self.included(base)
    __included(base, '[ExportHelper]')
  end

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
  # @param [Hash, nil] opt
  #
  # @options opt [String] :vendor     Default: `application_name`.
  # @options opt [String] :filter     Default: 'RefWorks Tagged Format'
  # @options opt [String] :url        The Virgo path that yields import data.
  #
  # @return [String]
  #
  # @overload refworks_export_url
  #   This is used as the form destination path when posting to RefWorks; the
  #   document reference(s) to export must be passed through a form field with
  #   name="ImportData" which contains the output from #export_as_refworks.
  #
  # @overload refworks_export_url(url: fullpath)
  #   This is used when initiating a RefWorks import by providing a callback
  #   URL, which outputs the results of #export_as_refworks.
  #
  # This method overrides:
  # @see BlacklightMarcHelper#refworks_export_url
  #
  # == Implementation Notes
  # The current Blacklight version of this method generates a serialized form
  # of MARC data for use with the RefWorks 'MARC Format' input filter.  The
  # Virgo 3 implementation generates 'RefWorks Tagged Format'; when that code
  # is copied into Virgo 4, this filter value here must be updated to reflect
  # the change.
  #
  # @see https://www.refworks.com/DirectExport.htm
  # @see https://www.refworks.com/content/products/import_filter.asp
  # @see https://www.refworks.com/refworks/help/Refworks.htm#RefWorks_Tagged_Format.htm
  #
  def refworks_export_url(opt = nil)
    url_opt = {
      vendor:   application_name,
      filter:   'MARC Format', # TODO: filter:   'RefWorks Tagged Format',
      encoding: '65001'
    }
    url_opt.merge!(opt) if opt.present?
    url_opt[:url] = url_for(url_opt) if url_opt[:url].is_a?(Hash)
    url_params = url_opt.map { |k, v| "#{k}=" + CGI.escape(v.to_s) }.join('&')
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
  # This method overrides:
  # @see BlacklightMarcHelper#refworks_solr_document_path
  #
  # == Usage Notes
  # This is here for consistency but is not used within Virgo.
  #
  def refworks_solr_document_path(options = nil)
    refworks_export_url(url: refworks_document_path(options))
  end

  # For exporting a single document in EndNote format.
  #
  # @param [Hash] options
  #
  # @options url_params [String] :id        Required: Document ID.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#single_endnote_catalog_path
  #
  # == Usage Notes
  # This is here for consistency but is not used within Virgo.
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
  # This method overrides:
  # @see BlacklightMarcHelper#render_refworks_texts
  #
  def render_refworks_texts(documents)
    render_exports(:refworks, documents)
  end

  # Combines a set of document references into one EndNote export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  # This method overrides:
  # @see BlacklightMarcHelper#render_endnote_texts
  #
  def render_endnote_texts(documents)
    render_exports(:endnote, documents)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Combines a set of document references into one Zotero RIS export string.
  #
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  def render_zotero_texts(documents)
    render_exports(:zotero, documents)
  end

  # For exporting a single document to RefWorks.
  #
  # @param [Array] args
  #
  # args[0]  [String, nil]            Document ID
  # args[-1] [Hash, nil]              Options
  #
  # @options args[-1] [String] :id    Document ID
  #
  # @return [String, nil]
  #
  def refworks_document_path(*args)
    opt = { caller: __method__, only_path: false }
    args << (args.last.is_a?(Hash) ? args.pop.merge(opt) : opt)
    export_document_path(*args)
  end

  # For exporting a single document in EndNote format.
  #
  # @param [Array] args
  #
  # args[0]  [String, nil]            Document ID
  # args[-1] [Hash, nil]              Options
  #
  # @options args[-1] [String] :id    Document ID
  #
  # @return [String, nil]
  #
  def endnote_document_path(*args)
    opt = { caller: __method__ }
    args << (args.last.is_a?(Hash) ? args.pop.merge(opt) : opt)
    export_document_path(*args)
  end

  # For exporting a single document in Zotero RIS format.
  #
  # @param [Array] args
  #
  # args[0]  [String, nil]            Document ID
  # args[-1] [Hash, nil]              Options
  #
  # @options args[-1] [String] :id    Document ID
  #
  # @return [String, nil]
  #
  def zotero_document_path(*args)
    opt = { caller: __method__ }
    args << (args.last.is_a?(Hash) ? args.pop.merge(opt) : opt)
    export_document_path(*args)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Combines a set of document references into a string in the format specified
  # by the caller.
  #
  # @param [Symbol] format
  # @param [Blacklight::Document, Array<Blacklight::Document>] documents
  #
  # @return [String]
  #
  def render_exports(format, documents)
    format = export_format[format] || format
    Array.wrap(documents).map { |doc|
      doc.export_as(format) if doc.exports_as?(format)
    }.compact.join("\n")
  end

  # URL which generates an export for a single document in the format specified
  # by the caller.
  #
  # @param [Array] args
  #
  # args[0]  [String, nil]            Document ID (here or in options)
  # args[-1] [Hash, nil]              Options
  #
  # @options args[-1] [String] :format      Export format (required).
  # @options args[-1] [String] :id          Document ID (required).
  # @options args[-1] [String] :caller      For error reporting.
  # @options args[-1] [String] :controller  Default: `current_lens_key`.
  # @options args[-1] [String] :action      Default: 'show'.
  #
  # @return [String, nil]
  #
  def export_document_path(*args)
    opt = args.last.is_a?(Hash) ? args.pop.dup : {}
    method = opt.delete(:caller)
    format = opt[:format] || method&.to_s&.sub(/_.*/, '')
    if format.blank?
      method ||= __method__
      Rails.logger.error { "ERROR: #{method}: no format specified" }
    else
      opt[:id]     = args.first if args.first.present?
      opt[:format] = export_format[format] || format
      opt[:action]     ||= opt[:id] ? :show : :index
      opt[:controller] ||= current_lens_key
      url_for(opt)
    end
  end

end

__loading_end(__FILE__)
