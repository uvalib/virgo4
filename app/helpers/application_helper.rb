# app/helpers/application_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Common helper methods.
#
module ApplicationHelper

  include UVA::Constants
  include UVA::Networks

  def self.included(base)
    __included(base, '[ApplicationHelper]')
  end

  # Displayed only if a method is set up to avoid returning *nil*.
  NO_LINK_DISPLAY = I18n.t('blacklight.no_link').html_safe.freeze

  RETURN_NIL = {
    doi_link: false,
    url_link: true,
  }

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Combine arrays and space-delimited strings to produce a space-delimited
  # string of CSS class names for use inline.
  #
  # @param [Array<String, Array>] args
  #
  # @yield [Array<String>]
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def css_classes(*args)
    yield(args) if block_given?
    args.flat_map { |a|
      a.is_a?(Array) ? a : a.to_s.squish.split(' ')
    }.compact.uniq.join(' ').html_safe
  end

  # Produce a click-able URL link.
  #
  # If only one argument is given, it is interpreted as the URL and the "label"
  # becomes the text of the URL.
  #
  # @param [String]      label
  # @param [String, nil] url
  # @param [Hash, nil]   opt
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def outlink(label, url = nil, opt = nil, &block)
    html_opt = { target: '_blank' }
    if block_given?
      opt = url
      url = label
      html_opt.merge!(opt) if opt.is_a?(Hash)
      link_to(url, html_opt, &block)
    else
      url ||= label
      html_opt.merge!(opt) if opt.is_a?(Hash)
      link_to(label, url, html_opt)
    end
  end

  # A close button for modal dialogs.
  #
  # @param [Hash, nil] opt            Button options.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def modal_close(opt = nil)
    html_opt = {
      class:          'blacklight-modal-close close',
      'data-dismiss': 'modal'
    }
    html_opt.merge!(opt) if opt.present?
    icon = html_opt.delete(:icon) || '&times;'.html_safe
    icon = content_tag(:span, icon, aria_hidden: true)
    tip  = t('blacklight.modal.close', default: '').presence
    html_opt[:title]        ||= tip if tip
    html_opt[:'aria-label'] ||= tip || 'Close'
    content_tag(:button, icon, html_opt)
  end

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # Render a field as hidden.
  #
  # @param [Hash] opt                 Supplied by the presenter.
  #
  # @return [String, Array]
  #
  def raw_value(opt = nil)
    values = (opt[:value] if opt.is_a?(Hash))
    values = Array.wrap(values).reject(&:blank?)
    (values.size > 1) ? values : values.first
  end

  # url_link
  #
  # @param [Hash]      value        Supplied by the presenter.
  # @param [Hash, nil] opt          Supplied internally to join multiple items.
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [Array<ActiveSupport::SafeBuffer>]
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def url_link(value, opt = nil)
    return raw_value(opt) unless request.format.html?
    values, opt = extract_config_value(value, opt)
    separator = opt.delete(:separator) || ' '
    result =
      Array.wrap(values).map { |url|
        parts = url.to_s.split('|', -3)
        next if (url = parts.first).blank?
        label = (parts.last.presence if parts.size > 1) || url
        outlink(label, url, opt)
      }.compact.join(separator).html_safe.presence
    result || (NO_LINK_DISPLAY unless RETURN_NIL[__method__])
  end

  # doi_link
  #
  # @param [Hash]      value        Supplied by the presenter.
  # @param [Hash, nil] opt          Supplied internally to join multiple items.
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def doi_link(value, opt = nil)
    return raw_value(options) unless request.format.html?
    value, opt = extract_config_value(value, opt)
    separator = opt.delete(:separator)
    result =
      Array.wrap(value).map { |url|
        next if url.blank?
        label = url.sub(%r{^https?://.*doi\.org/}, '')
        outlink(label, url, opt)
      }.compact.join(separator).html_safe.presence
    result || (NO_LINK_DISPLAY unless RETURN_NIL[__method__])
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # extract_config_options
  #
  # @param [Hash]      value
  # @param [Hash, nil] opt
  #
  # @option value [Hash]   :html_options        See below.
  # @option value [Hash]   :separator_options   See below.
  # @option value [String] :separator
  #
  # @option opt   [String] :separator
  #
  # @return [Array<(String, Hash)>]
  # @return [Array<(Array<String>, Hash)>]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_value(value, opt = nil)
    opt ||= {}
    case value
      when Hash, Blacklight::Configuration::Field
        opt   = extract_config_options(value[:config], opt)
        value = value[:value]
      when Array
        opt   = opt.merge(separator: HTML_NEW_LINE) unless opt.key?(:separator)
    end
    [value, opt]
  end

  # extract_config_options
  #
  # @param [Hash]      config
  # @param [Hash, nil] opt
  #
  # @option config [Hash]   :html_options        See below.
  # @option config [Hash]   :separator_options   See below.
  # @option config [String] :separator
  #
  # @option opt    [String] :separator
  #
  # @return [Hash]
  #
  # Options separating multiple:
  # @see ActionView::Helper::OutputSafetyHelper#to_sentence
  #
  def extract_config_options(config, opt = nil)
    opt ||= {}
    if config.present?
      opt = opt.merge(config[:html_options] || {})
      if config.key?(:separator)
        opt.merge!(separator: config[:separator])
      elsif config[:separator_options].present?
        opt.merge!(separator: config[:separator_options].first.last)
      end
    end
    opt
  end

end

__loading_end(__FILE__)
