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
  # @param [Hash]         opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  # @see #availability_indicator
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
  # @option opt [Symbol] :format
  # @option opt [String] :av_mode
  # @option opt [String] :av_label
  # @option opt [String] :disabled
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  def availability_indicator(**opt)
    html_opt = {
      av_mode:  'unavailable',
      class:    'availability-indicator',
      disabled: true
    }
    html_opt.merge!(opt.except(:format))
    av_mode  = html_opt.delete(:av_mode)
    av_label = html_opt.delete(:av_label)
    av_label =
      case av_label
        when false     then ''
        when true, nil then av_mode.to_s.capitalize
        else                av_label.to_s
      end
    if non_html?(opt)
      av_label
    else
      disabled = html_opt.delete(:disabled)
      html_opt[:class] =
        css_classes(html_opt[:class]) do |classes|
          classes << av_mode
          classes << 'active' unless disabled
        end
      html_opt.except!(:tabindex, :'aria-expanded') if disabled
      content_tag(:span, av_label, html_opt)
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
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  # @see #availability_indicator
  #
  def non_circ_indicator(**opt)
    html_opt = {
      av_mode:  'non-circ',
      av_label: HOLDING_LABEL[:non_circ],
      title:    HOLDING_TOOLTIP[:non_circ]
    }
    html_opt.merge!(opt)
    availability_indicator(html_opt)
  end

  # A holdings row for a single item (copy, volume, part, etc.).
  #
  # @param [SolrDocument] doc
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [Hash]                      Otherwise.
  #
  # @see #availability_row
  # @see #non_circ_indicator
  # @see #disbound_icon
  #
  def item_row(doc, holding, copy, **opt)
    fmt  = opt.slice(:format)
    html = html?(fmt)

    # Add CSS classes to indicate the requests for which it is eligible.
    if html
      types = request_type_classes(holding, copy)
      opt = opt.merge(class: css_classes(opt[:class], types)) if types.present?
    end

    # Create the Availability column with additional elements as necessary.
    button_opt = html ? { title: HOLDING_TOOLTIP[:item], disabled: true } : fmt
    availability = availability_button(holding, copy, button_opt)
    icons = []
    icons << non_circ_indicator(fmt) unless copy.circulates?
    icons << disbound_icon(fmt) if doc.despined?(copy.barcode)
    if icons.present?
      icons.unshift(availability)
      availability = html ? safe_join(icons, ' ') : icons.join(', ')
    end

    columns = {
      library:      holding.library.name,
      location:     location_text(holding, copy),
      map:          link_to_map(holding, copy, fmt),
      availability: availability,
      call_number:  holding.call_number
    }
    availability_row(columns, **opt)
  end

  # A holdings row for non-catalog "unique" sites like Kluge-Ruhe.
  #
  # @param [SolrDocument] doc
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [Hash]                      Otherwise.
  #
  # @see #availability_row
  #
  def unique_site_row(doc, **opt)
    columns = {
      library:      doc.values(:library_f).join(', '),
      location:     doc.values(:location_f).join(', '),
      map:          ('<!-- no map -->'.html_safe if html?(opt)),
      availability: HOLDING_MESSAGE[:unique_site],
      call_number:  doc.call_numbers.first
    }
    availability_row(columns, **opt)
  end

  # A holdings row for displaying (non-actionable) information about a lost or
  # missing item.
  #
  # @param [SolrDocument] doc
  # @param [String]       lib
  # @param [String]       note
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [Hash]                      Otherwise.
  #
  # @see #availability_row
  # @see IlsAvailability#lost
  #
  def missing_row(doc, lib, note, **opt)
    fmt = opt.slice(:format)
    loc = note.capitalize
    loc = content_tag(:em, loc) if html?(fmt)
    columns = {
      library:      lib,
      location:     loc,
      map:          link_to_map(nil, nil, fmt),
      availability: availability_button(nil, nil, fmt),
      call_number:  doc.call_numbers.first
    }
    availability_row(columns, **opt)
  end

  # A (solitary) holdings row which indicates that no meaningful holdings could
  # be extracted from availability information.
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  # @see #availability_spanning_row
  #
  def no_info_row(**opt)
    opt     = opt.dup
    message = opt.delete(:message) || HOLDING_MESSAGE[:no_info]
    availability_spanning_row(message, opt)
  end

  # A (solitary) holdings row which indicates that there was error in the
  # acquisition of availability information.
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  # @see #availability_spanning_row
  #
  def error_row(**opt)
    opt     = opt.dup
    error   = opt.delete(:error)
    message = opt.delete(:message) || HOLDING_MESSAGE[:error]
    message += ": #{error}" if error.present?
    message = content_tag(:div, message, class: 'error') if html?(opt)
    availability_spanning_row(message, opt)
  end

  # availability_row
  #
  # @param [Hash]      columns
  # @param [Hash, nil] opt
  #
  # @option opt [Symbol] :format
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [Hash]                      Otherwise.
  #
  # @see #holdings_element
  #
  def availability_row(columns, **opt)
    if non_html?(opt)
      columns
    else
      holdings_element(opt) do
        columns.map do |attr, value|
          content_tag(:td, value, class: "holding-data #{attr}")
        end
      end
    end
  end

  # A holdings row with content spanning the entire row.
  #
  # @param [String, ActiveSupport::SafeBuffer] content
  # @param [Hash, nil]                         opt
  #
  # @option opt [Symbol] :format
  #
  # @return [ActiveSupport::SafeBuffer] If `html?(opt)`.
  # @return [String]                    Otherwise.
  #
  # @see #holdings_element
  #
  def availability_spanning_row(content, **opt)
    if non_html?(opt)
      content
    else
      holdings_element(opt) do
        content_tag(:td, content, colspan: 5, class: 'holding-data no-info')
      end
    end
  end

  # An HTML holdings row wrapping content supplied through the block.
  #
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Usage Notes
  # `html?(opt)` is assumed to be *true*.
  #
  def holdings_element(**opt)
    css_class = css_classes(HOLDING_CSS_CLASS, opt[:class])
    content_tag(:tr, opt.merge(class: css_class)) do
      lines = [nil]
      lines += Array.wrap(yield)
      lines << nil
      safe_join(lines, "\n")
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Indicate whether the options imply or specify HTML format.
  #
  # @param [Hash] opt
  #
  def html?(opt)
    opt[:format].blank? || (opt[:format].to_s == 'html')
  end

  # Indicate whether the options specify a non-HTML format.
  #
  # @param [Hash] opt
  #
  def non_html?(opt)
    !html?(opt)
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
      location.summaries.map do |summary|
        cn   = summary.call_number.presence
        text = summary.text.presence
        note = summary.note.presence
        summary_group_classes =
          css_classes('summary-group') do |classes|
            classes << 'note-entry' if note && (cn || text)
          end
        content_tag(:div, class: summary_group_classes) do
          parts = []
          parts << content_tag(:div, cn, class: 'summary-call-number') if cn
          parts << content_tag(:div, text, class: 'summary-text')      if text
          parts << content_tag(:div, note, class: 'summary-note')      if note
          safe_join(parts)
        end
      end

    content_tag(:div, class: 'holding-group') do
      location_name + safe_join(summaries, "\n")
    end
  end

  # ===========================================================================
  # :section: TODO: Special - RELOCATE (?)
  # ===========================================================================

  public

  # Text returned for non-HTML formats.
  #
  # @type [String]
  #
  DISBOUND_LABEL = 'disbound'

  # Informational text displayed in the popup.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  DISBOUND_TEXT = <<~HEREDOC.html_safe.freeze
    This item was disbound in the UVA Library’s first digitization project,
    1998-99, which included a select group of public domain books.
  HEREDOC

  # Tooltip shown if the popup is closed.
  #
  # @type [String]
  #
  DISBOUND_OPEN  = 'Click for circulation status explanation.'

  # Tooltip shown if the popup is open.
  #
  # @type [String]
  #
  DISBOUND_CLOSE = 'Click to dismiss this popup.'

  # disbound_help_icon
  #
  # @param [Hash, nil] opt
  #
  # @option opt [Symbol] :format
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def disbound_icon(**opt)

    return DISBOUND_LABEL if non_html?(opt)

    html_opt = {
      class:         'disbound-help-link',
      role:          'button',
      tabindex:      0,
      title:         DISBOUND_OPEN,
      'aria-label':  DISBOUND_OPEN
    }
    html_opt.merge!(opt.except(:format))

    icon_opt = {
      class:         'fa fa-question-circle disbound-help-icon',
      'aria-hidden': true
    }
    icon = content_tag(:div, '', icon_opt)

    text_opt = {
      class:         'disbound-help-container',
      role:          'note',
      title:         DISBOUND_CLOSE,
      'aria-label':  DISBOUND_CLOSE,
    }
    text = content_tag(:div, DISBOUND_TEXT, text_opt)

    content_tag(:div, html_opt) do
      icon + text
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

  # Text for SC locations.
  #
  # @type [Hash{Symbol=>String}]
  #
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

  # Text used to indicate that no map link is provided.
  #
  # @type [String]
  #
  NO_MAP_LABEL = 'N/A'

  # The link to a map for the item's physical location.
  #
  # @param [Ils::Holding] holding
  # @param [Ils::Copy]    copy
  # @param [Boolean]      missing     Show #NO_MAP_LABEL for missing map.
  # @param [Hash, nil]    opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                       If there was no map for the item and
  #                                       *na_map* was set to *false*.
  #
  # == Usage Notes
  # The default for :na_map depends on the format:
  # *true*  if html?(opt)
  # *false* if non_html?(opt)
  #
  def link_to_map(holding, copy, missing: nil, **opt)
    map = nil # TODO: stacks map links
=begin
    #map = copy&.stacks_map(holding)
    map = Map.find_best_map(holding, copy) if copy.available?
=end
    if non_html?(opt)
      map&.url || (NO_MAP_LABEL if missing.is_a?(TrueClass))
    elsif map&.url
      outlink('Map', map.url, class: 'map-link', title: 'Map')
    elsif !missing.is_a?(FalseClass)
      content_tag(:span, NO_MAP_LABEL, class: 'map-indicator no-map')
    end
  end

  # =========================================================================
  # :section: TODO: Kluge-Ruhe - RELOCATE
  # =========================================================================

  public

  # Document types to which this module applies.
  #
  # @type [Hash{Symbol=>Hash}]
  #
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
