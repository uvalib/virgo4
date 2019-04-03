# app/helpers/availability_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module AvailabilityHelper

  HOLDING_CSS_CLASS  = 'holding'

  HOLDING_I18N_SCOPE = 'blacklight.availability.holding'

  HOLDING_MESSAGE = I18n.t("#{HOLDING_I18N_SCOPE}.message").deep_freeze
  HOLDING_TOOLTIP = I18n.t("#{HOLDING_I18N_SCOPE}.tooltip").deep_freeze
  HOLDING_LABEL   = I18n.t("#{HOLDING_I18N_SCOPE}.label").deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Return "Available" or "Unavailable".
  #
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  #
  # @return [String]                  Non-blank result.
  #
  def availability_label(holding, copy)
    result = nil
    status = nil # TODO: workflows (e.g. "medium-rare")
=begin
    status = workflow_status_field(__method__, holding, copy).presence
=end
    result ||= status.join(' ') if status.present?
    result ||= 'Available'      if copy&.available?
    result ||= 'Unavailable'
    result  += ' to Order'      if copy&.not_ordered?
    result
  end

  # Style to be used for availability text.
  #
  # @param [Ils::Holding] _holding
  # @param [Ils::Copy]    copy
  #
  # @return [String]                  Non-blank result.
  #
  def availability_mode(_holding, copy)
    result = nil
    status = nil # TODO: workflows (e.g. "medium-rare")
=begin
    status = workflow_status_field(__method__, holding, copy).presence
=end
    result ||= status.join(' ') if status.present?
    result ||= 'available'      if copy&.available?
    result || 'unavailable'
  end

  # The availability indicator as a button.
  #
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  # @param [Hash]         opt         Passed to self#availability_link
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def availability_button(holding, copy, **opt)
    opt = opt.dup
    opt[:av_mode]  ||= availability_mode(holding, copy)
    opt[:av_label] ||= availability_label(holding, copy)
=begin
    availability_link(opt) # TODO: availability popup (?)
=end
    availability_indicator(opt)
  end

  # The base availability indicator element.
  #
  # @param [Hash, nil] opt
  #
  # @option opt [String] :av_mode
  # @option opt [String] :av_label
  # @option opt [String] :disabled
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def availability_indicator(**opt)
    html_opt = {
      av_mode:  'unavailable',
      class:    'availability-indicator',
      disabled: true
    }
    html_opt.merge!(opt) if opt.present?
    av_mode  = html_opt.delete(:av_mode)
    av_label = html_opt.delete(:av_label)
    disabled = html_opt.delete(:disabled)

    html_opt[:class] =
      css_classes(html_opt[:class]) do |classes|
        classes << av_mode
        classes << 'active' unless disabled
      end
    html_opt.except!(:tabindex, :'aria-expanded') if disabled

    content_tag(:span, html_opt) do
      case av_label
        when false     then ''
        when true, nil then av_mode.to_s.capitalize
        else                av_label.to_s
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # non_circ_indicator
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def non_circ_indicator(**opt)
    html_opt = {
      av_mode:  'non-circ',
      av_label: HOLDING_LABEL[:non_circ],
      title:    HOLDING_TOOLTIP[:non_circ]
    }
    html_opt.merge!(opt) if opt.present?
    availability_indicator(html_opt)
  end

  # A holdings row for a single item (copy, volume, part, etc.).
  #
  # @param [SolrDocument] doc
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #availability_row
  # @see #non_circ_indicator
  # @see #disbound_icon
  #
  def item_row(doc, holding, copy, **opt)

    # Add CSS classes to indicate the requests for which it is eligible.
    types = request_type_classes(holding, copy)
    opt = opt.merge(class: css_classes(opt[:class], types)) if types.present?

    button_opt = { title: HOLDING_TOOLTIP[:item], disabled: true }
    columns = {
      'library-name':  holding.library.name,
      'location-name': location_text(holding, copy),
      'map-it':        link_to_map(holding, copy),
      'availability':  availability_button(holding, copy, button_opt),
      'call-number':   holding.call_number
    }

    # Additional elements for the Availability column.
    columns[:availability] << non_circ_indicator unless copy.circulates?
    columns[:availability] << disbound_icon if doc.despined?(copy.barcode)

    availability_row(columns, **opt)
  end

  # A holdings row for non-catalog "unique" sites like Kluge-Ruhe.
  #
  # @param [SolrDocument] doc
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #availability_row
  #
  def unique_site_row(doc, **opt)
    columns = {
      'library-name':  doc.values(:library_f).join(', '),
      'location-name': doc.values(:location_f).join(', '),
      'map-it':        '<!-- no map -->'.html_safe,
      'availability':  HOLDING_MESSAGE[:unique_site],
      'call-number':   doc.call_numbers.first
    }
    availability_row(columns, **opt)
  end

  # A holdings row for displaying (non-actionable) information about a lost or
  # missing item.
  #
  # @param [SolrDocument] doc
  # @param [String]       lib
  # @param [String]       copy
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see IlsAvailability#lost
  #
  # @see #availability_row
  #
  def missing_row(doc, lib, copy, **opt)
    columns = {
      'library-name':  lib,
      'location-name': content_tag(:em, ERB::Util.h(copy.capitalize)),
      'map-it':        link_to_map(nil, nil),
      'availability':  availability_button(nil, nil),
      'call-number':   doc.call_numbers.first
    }
    availability_row(columns, **opt)
  end

  # A (solitary) holdings row which indicates that no meaningful holdings could
  # be extracted from availability information.
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #availability_spanning_row
  #
  def no_info_row(**opt)
    opt = opt.dup
    message = opt.delete(:message) || HOLDING_MESSAGE[:no_info]
    availability_spanning_row(message, opt)
  end

  # A (solitary) holdings row which indicates that there was error in the
  # acquisition of availability information.
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # @see #availability_spanning_row
  #
  def error_row(**opt)
    opt     = opt.dup
    error   = opt.delete(:error)
    message = opt.delete(:message) || HOLDING_MESSAGE[:error]
    message += ": #{error}" if error.present?
    message = content_tag(:div, ERB::Util.h(message), class: 'btn-danger')
    availability_spanning_row(message, opt)
  end

  # availability_row
  #
  # @param [Hash]      columns
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def availability_row(columns, **opt)
    css_class = css_classes(HOLDING_CSS_CLASS, opt[:class])
    content_tag(:tr, opt.merge(class: css_class)) do
      columns.map { |attr, value|
        content_tag(:td, class: "holding-data #{attr}") do
          ERB::Util.h(value)
        end
      }.join("\n").html_safe
    end
  end

  # A holdings row with content spanning the entire row.
  #
  # @param [String, ActiveSupport::SafeBuffer] content
  # @param [Hash, nil]                         opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def availability_spanning_row(content, **opt)
    css_class = css_classes(HOLDING_CSS_CLASS, opt[:class])
    content_tag(:tr, opt.merge(class: css_class)) do
      content_tag(:td, colspan: 5, class: 'holding-data no-info') do
        ERB::Util.h(content)
      end
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Render a holdings summary location.
  #
  # @param [Ils::HomeLibrary]
  # @param [Ils::HomeLocation]
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def location_summary(library, location)
    location_name = library.name
    location_name += " - #{location.name}" if location.name.present?
    location_name = content_tag(:div, location_name, class: 'home-location')

    summaries =
      location.summaries.map { |summary|
        cn   = summary.call_number.presence
        text = summary.text.presence
        note = summary.note.presence
        summary_group_classes =
          css_classes('summary-group') do |classes|
            classes << 'note-entry' if note && (cn || text)
          end
        content_tag(:div, class: summary_group_classes) do
          [].tap { |parts|
            parts << content_tag(:div, cn, class: 'summary-call-number') if cn
            parts << content_tag(:div, text, class: 'summary-text') if text
            parts << content_tag(:div, note, class: 'summary-note') if note
          }.join.html_safe
        end
      }.join("\n").html_safe

    content_tag(:div, class: 'holding-group') do
      location_name + summaries
    end
  end

  # ===========================================================================
  # :section: TODO: Special - RELOCATE (?)
  # ===========================================================================

  public

  DISBOUND_TEXT = <<~HEREDOC.html_safe.freeze
    This item was disbound in the UVA Library’s first digitization project,
    1998-99, which included a select group of public domain books.
  HEREDOC

  DISBOUND_OPEN  = 'Click for circulation status explanation.'
  DISBOUND_CLOSE = 'Click to dismiss this popup.'

  # disbound_help_icon
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def disbound_icon
    container_opt = {
      class:         'disbound-help-link',
      role:          'button',
      tabindex:      0,
      title:         DISBOUND_OPEN,
      'aria-label':  DISBOUND_OPEN
    }
    icon_opt = {
      class:         'fa fa-question-circle disbound-help-icon',
      'aria-hidden': true
    }
    text_opt = {
      class:         'disbound-help-container',
      role:          'note',
      title:         DISBOUND_CLOSE,
      'aria-label':  DISBOUND_CLOSE,
    }
    content_tag(:div, container_opt) do
      content_tag(:div, '', icon_opt) +
      content_tag(:div, DISBOUND_TEXT, text_opt)
    end
  end

  # ===========================================================================
  # :section: TODO: Special Collections - RELOCATE(?)
  # ===========================================================================

  public

  # The location to display in availability results for an item copy.
  #
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  #
  # @return [String]
  # @return [nil]
  #
  def location_text(holding, copy)
    return unless holding && copy
    sc = holding.special_collections? && !copy.sc_exhibit?
    sc ? sc_location_text(copy) : copy.current_location.name
  end

  # ===========================================================================
  # :section: TODO: Special Collections - RELOCATE
  # ===========================================================================

  public

  SC_LOCATION_TEXT = {
    default:    'Special Collections',
    in_process: 'Contact Special Collections',
    sc_ivy:     'Request from Ivy'
  }.freeze

  # Generates Special Collections location text.
  #
  # The rules for what to display are:
  #
  # - If home location is SC-IVY and current location is SC-IVY,
  #     then location should read 'Request from Ivy'.
  # - If home location is SC-IVY and current location is SC-IN-PROC,
  #     then location should read 'Contact Special Collections'.
  # - If home location is SC-IVY and current location is IN-PROCESS,
  #     then location should read 'Contact Special Collections'.
  #
  # Otherwise, display "Special Collections".
  #
  # @param [Firehose::Copy] copy
  #
  # @return [String]
  #
  # @see self#location_text
  #
  def sc_location_text(copy)
    result =
      if copy.home_location.sc_ivy?
        if copy.in_process?
          SC_LOCATION_TEXT[:in_process]
        elsif copy.current_location.sc_ivy?
          SC_LOCATION_TEXT[:sc_ivy]
        end
      end
    result || SC_LOCATION_TEXT[:default]
  end

  # ===========================================================================
  # :section: TODO: Maps - RELOCATE
  # ===========================================================================

  public

  # The link to a map for the item's physical location.
  #
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  # @param [Boolean]      na_map      Show "N/A" for missing map.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If there was no map for the item and
  #                                       *na_map* was set to *false*.
  #
  def link_to_map(holding, copy, na_map = true)
    map = nil # TODO: stacks map links
=begin
    #map = copy&.stacks_map(holding)
    map = Map.find_best_map(holding, copy) if copy.available?
=end
    if map
      outlink('Map', map.url, class: 'map-link', title: 'Map')
    elsif na_map
      content_tag(:span, 'N/A', class: 'map-indicator no-map')
    end
  end

  # =========================================================================
  # :section: TODO: Kluge-Ruhe - RELOCATE
  # =========================================================================

  public

  # Document types to which this module applies.
  UNIQUE_SITE = {
    kluge: {
      label: 'Kluge-Ruhe Study Center',
      url:   'http://www.kluge-ruhe.org/publications/study-center',
      name:  nil, # same as label
      site:  'Kluge-Ruhe Aboriginal Art Collection of the University of Virginia'
    },
    cnhi: {
      label: 'Bjoring Center for Nursing Historical Inquiry',
      url:   'https://www.nursing.virginia.edu/research/cnhi/',
      name:  'Eleanor Crowder Bjoring Center for Nursing Historical Inquiry',
      site:  'University of Virginia School of Nursing, McLeod Hall #1010'
    }
  }.freeze

  # Indicate whether the given document or type symbol is associated with a
  # unique site to be handled like Kluge-Ruhe entries.
  #
  # @param [SolrDocument, String, Symbol] doc
  #
  # @return [Symbol]
  # @return [nil]
  #
  def unique_site_type(doc)
    case doc
      when SolrDocument
        doc.values(:doc_type_f).find { |type| UNIQUE_SITE.key?(type.to_sym) }
      when Symbol, String
        doc.to_sym if UNIQUE_SITE.key?(doc.to_sym)
    end
  end

  # ===========================================================================
  # :section: TODO: Request handlers - RELOCATE
  # ===========================================================================

  public

  # A table which indicates the request types that may be applicable to the
  # given holding.
  #
  # @param [Ils::Holding] holding
  #
  # @return [Hash{Symbol=>Handler}]
  #
  def request_handlers(holding)
    [:ils, :ill_ivy, :ill_leo, :sc].map { |type|
      handler = nil # TODO: UVA::Request::Handler[type]
      [type, handler] if handler&.can_request?(holding)
    }
  end

  # A list of request types that are applicable to the copy (or the holding if
  # *copy* is *nil*).
  #
  # @param [Ils::Holding]   holding
  # @param [Ils::Copy, nil] copy
  #
  # @return [Array<Symbol>]
  #
  def request_types(holding, copy = nil)
    handlers = request_handlers(holding)
    if copy
      handlers.map { |type, handler|
        type if handler&.can_request?(copy)
      }.compact
    else
      handlers.keys
    end
  end

  # CSS classes indicating the request types that are applicable to the copy
  # (or the holding if *copy* is *nil*).
  #
  # @param [Ils::Holding]   holding
  # @param [Ils::Copy, nil] copy
  #
  # @return [String]
  #
  def request_type_classes(holding, copy = nil)
    request_types(holding, copy).map { |type| "type-#{type}" }
  end

end

__loading_end(__FILE__)
