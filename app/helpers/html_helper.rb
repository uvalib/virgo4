# app/helpers/html_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Methods for dealing with the construction of HTML elements.
#
module HtmlHelper

  def self.included(base)
    __included(base, '[HtmlHelper]')
  end

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

  # Merge two or more options hashes where the result :class value is the
  # concatenation of of all of the options hashes.
  #
  # @param [Array<Hash>] args
  #
  # @return [Hash]                    A new hash with the merged arguments.
  #
  def merge_html_options(*args)
    merge_html_options!({}, *args)
  end

  # Merge *other* into *target* but append `other[:class]` to `target[:class]`.
  #
  # @param [Hash]        target
  # @param [Array<Hash>] args
  #
  # @return [Hash]                    The modified *target* hash.
  #
  def merge_html_options!(target, *args)
    target ||= {}
    args = args.flatten(1).select { |arg| arg.is_a?(Hash) && arg.present? }
    other_css = args.map { |arg| arg[:class] }.reject(&:blank?)
    target[:class] = css_classes(target[:class], *other_css)
    args.each { |arg| target.merge!(arg.except(:class)) }
    target
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
    merge_html_options!(html_opt, opt)
    icon = html_opt.delete(:icon) || '&times;'.html_safe
    icon = content_tag(:span, icon, aria_hidden: true)
    tip  = t('blacklight.modal.close', default: '').presence
    html_opt[:title]        ||= tip if tip
    html_opt[:'aria-label'] ||= tip || 'Close'
    content_tag(:button, icon, html_opt)
  end

end

__loading_end(__FILE__)
