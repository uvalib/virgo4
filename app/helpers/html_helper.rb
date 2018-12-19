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

  # If included from a model, some additional setup is required to support
  # methods that are normally only available from a view like :link_to.
  unless defined?(url_for)
    include ActionView::Helpers::UrlHelper
    include Rails.application.routes.url_helpers
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

  # Recursively mark strings as HTML-safe.  The method assumes that the strings
  # are already properly escaped.
  #
  # If a block is given it is applied to each string found.
  #
  # @param [String, Array<String>, Hash{Object=>String}] item
  #
  # @return [Object]                  A copy of *item* with HTML-safe strings.
  #
  def html_safe(item)
    case item
      when String
        item = yield(item) if block_given?
        item.html_safe
      when Array
        item.map { |v| html_safe(v) }
      when Hash
        item.map { |k, v| [k, html_safe(v)] }.to_h.with_indifferent_access
      else
        item
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

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
    link_args = [label]
    if block_given?
      # *label* holds the URL in this case.
      opt = url
    else
      link_args << (url || label)
    end
    html_opt = { target: '_blank' }
    html_opt.merge!(opt) if opt.is_a?(Hash)
    if html_opt[:target] == '_blank'
      html_opt[:rel] ||= 'noopener'
      html_opt[:title] &&= "#{html_opt[:title]}\n(opens in a new window)"
      html_opt[:title] ||= 'Opens in a new window'
    end
    link_to(*link_args, html_opt, &block)
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

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Produce a click-able link to a path.
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
  def path_link(label, url = nil, opt = nil, &block)
    link_args = [label]
    if block_given?
      # *label* holds the URL in this case.
      opt = url
    elsif url.is_a?(Hash)
      #link_args << url.merge(only_path: true) # TODO
      link_args <<
        begin
          u = url.compact
          c = url.delete(:controller) || 'catalog'
          a = url.delete(:action)
          path = +"/#{c}"
          path << "/#{a}" if a
          path << "?#{url.to_query}" unless url.blank?
          path
        end
    else
      link_args << (url || label)
    end
    html_opt = {}
    html_opt.merge!(opt) if opt.is_a?(Hash)
    link_to(*link_args, html_opt, &block)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  E_CHAR      = %q([a-z0-9!#$%&'*/=?^_`{|}~+-])
  E_CNAME     = "#{E_CHAR}([.]?#{E_CHAR})*"
  E_QNAME     = %Q("[^"]+")
  E_NAME      = "(#{E_CNAME}|#{E_QNAME})"
  E_HOST      = '[a-z0-9][a-z0-9.:-]*[a-z0-9]'
  E_ADDR      = '\[\d[.\d]*\d\]'
  E_COMMENT   = '\([^)]*\)'
  E_DOMAIN    = "(#{E_COMMENT})?(#{E_HOST}|#{E_ADDR})(#{E_COMMENT})?"
  E_ADDRESS   = "#{E_NAME}@#{E_DOMAIN}"
  EMAIL_REGEX = Regexp.new(E_ADDRESS, Regexp::IGNORECASE)

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A regular expression for detecting e-mail addresses.
  #
  # @return [Regexp]
  #
  # @see self#EMAIL_REGEX
  # @see https://tools.ietf.org/html/rfc5322#page-16
  #
  # == Implementation Notes
  # This is a rough approximation that should cover most forms of e-mail
  # addresses that are likely to be encountered in metadata.
  #
  def email_regex
    EMAIL_REGEX
  end

  # Generate HTML for an email link.
  #
  # @param [String] address
  #
  def email_link(address)
    %Q(<a href="mailto:#{address}">#{address}</a>)
  end

end

__loading_end(__FILE__)
