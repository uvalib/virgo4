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

  # URL for RefWorks service import.
  #
  # @type [String]
  #
  # @see self#refworks_export_url
  #
  REFWORKS_URL = 'https://www.refworks.com/express/expressimport.asp'

  # Indicate whether the "librarian view" modal should use a monospace font.
  #
  # @type [TrueClass, FalseClass]
  #
  # @see self#monospace_marc_view?
  #
  MARC_VIEW_MONOSPACE = true

  # ===========================================================================
  # :section: BlacklightMarcHelper overrides
  # ===========================================================================

  public

  # refworks_export_url
  #
  # @param [Hash, nil] opt
  #
  # @option opt [String] :vendor      Default: `application_name`.
  # @option opt [String] :filter      Default: 'RefWorks Tagged Format'
  # @option opt [String] :url         The Virgo path that yields import data.
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
  # @return [String]
  #
  # @see self#REFWORKS_URL
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
  # @option url_params [String] :id         Required: Document ID.
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
  # @option url_params [String] :id         Required: Document ID.
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
  # @option args[-1] [String] :id     Document ID
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
  # @option args[-1] [String] :id     Document ID
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
  # @option args[-1] [String] :id     Document ID
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
  # @option args[-1] [String] :format       Export format (required).
  # @option args[-1] [String] :id           Document ID (required).
  # @option args[-1] [String] :caller       For error reporting.
  # @option args[-1] [String] :controller   Default: `current_lens_key`.
  # @option args[-1] [String] :action       Default: 'show'.
  #
  # @return [String, nil]
  #
  def export_document_path(*args)
    opt = args.last.is_a?(Hash) ? args.pop.dup : {}
    method = opt.delete(:caller)
    format = opt[:format] || method&.to_s&.sub(/_.*/, '')
    if format.blank?
      method ||= __method__
      Log.error { "ERROR: #{method}: no format specified" }
    else
      opt[:id]     = args.first if args.first.present?
      opt[:format] = export_format[format] || format
      opt[:action]     ||= opt[:id] ? :show : :index
      opt[:controller] ||= current_lens_key
      url_for(opt)
    end
  end

  # ===========================================================================
  # :section: Librarian View
  # ===========================================================================

  protected

  # Indicate whether the "librarian view" modal should use a monospace font.
  #
  # @see self#MARC_VIEW_MONOSPACE
  #
  def marc_view_monospace?
    MARC_VIEW_MONOSPACE
  end

  # Render MARC for "librarian view".
  #
  # @param [Blacklight::Lens::Document] doc
  # @param [Hash, nil]                  opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def render_marc(doc, opt = nil)
    (record = doc&.to_marc) && render_marc_record(record, opt)
  end

  # Render a MARC record for "librarian view".
  #
  # @param [MARC::Record] record
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_record(record, opt = nil)
    opt = opt ? opt.dup : {}
    opt[:class] =
      Array.wrap(opt[:class]).tap { |css|
        css << 'modal-body' if css.blank?
        css << 'monospace'  if marc_view_monospace?
      }.compact.join(' ')
    content_tag(:div, opt) do
      lines = [render_marc_leader(record)]
      lines += render_marc_fields(record)
      lines.compact.join("\n").html_safe
    end
  end

  # Render MARC record fields for "librarian view".
  #
  # @param [MARC::Record] record
  # @param [Range, nil]   valid_tags  Default: '000'..'999'.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  #
  def render_marc_fields(record, valid_tags = nil)
    valid_tags ||= '000'..'999'
    record.map { |field|
      render_marc_field(field) if valid_tags.include?(field.tag)
    }.compact
  end

  # Render a MARC record leader field for "librarian view".
  #
  # @param [MARC::Record] record
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_leader(record)
    label = t('blacklight.search.librarian_view.leader', default: 'LEADER')
    value = record.leader
    content_tag(:div, class: 'leader field') do
      render_marc_tag(label) + render_marc_control_field(value)
    end
  end

  # Render a MARC subfield for "librarian view".
  #
  # @param [MARC::ControlField, MARC::DataField] field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_field(field)
    tag = render_marc_tag(field)
    ctl = field.is_a?(MARC::ControlField)
    val = ctl ? render_marc_control_field(field) : render_marc_subfields(field)
    content_tag(:div, (tag + val), class: 'field')
  end

  # Render a MARC field tag for "librarian view".
  #
  # @param [MARC::ControlField, MARC::DataField, String] field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_tag(field)
    content_tag(:div, class: 'tag_ind') do
      case field
        when MARC::DataField
          empty = '&nbsp'.html_safe
          tag  = marc_span(field.tag, class: 'tag')
          tag << marc_span((field.indicator1.presence || empty), class: 'ind1')
          tag << marc_span((field.indicator2.presence || empty), class: 'ind2')
        when MARC::ControlField
          marc_span(field.tag, class: 'tag')
        else
          ERB::Util.h(field.to_s)
      end
    end
  end

  # Render a MARC control field value for "librarian view".
  #
  # @param [MARC::ControlField, String] field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_control_field(field)
    value = field.respond_to?(:value) ? field.value : field
    marc_span(value, class: 'control_field_values')
  end

  # Render a MARC subfield values for "librarian view".
  #
  # @param [MARC::DataField] field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_subfields(field)
    content_tag(:div, class: 'subfields') do
      field.map { |sf| render_marc_subfield(sf) }.join("\n").html_safe
    end
  end

  # Render a MARC subfield for "librarian view".
  #
  # @param [MARC::Subfield] subfield
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_marc_subfield(subfield)
    content_tag(:span, class: 'subfield') do
      s = ''.html_safe
      s << marc_span(subfield.code,  class: 'sub_code')
      s << marc_span('|'.html_safe,  class: 'sub_separator')
      s << marc_span(subfield.value, class: 'sub_value')
    end
  end

  # ===========================================================================
  # :section: Librarian View
  # ===========================================================================

  private

  # Render a value in a span for "librarian view".
  #
  # @param [String]    value
  # @param [Hash, nil] opt            Options for the <span>.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def marc_span(value, opt = nil)
    value = value.to_s
    case value
      when /^(http|https):/
        opt = opt ? opt.dup : {}
        css_class = Array.wrap(opt[:class])
        css_class << 'url'
        opt[:class] = css_class.reject(&:blank?).uniq.join(' ')
        opt[:target] ||= '_blank'
        link_to(ERB::Util.h(value), value, opt)
      else
        content_tag(:span, ERB::Util.h(value), (opt || {}))
    end
  end

end

__loading_end(__FILE__)
