# app/helpers/about_helper/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AboutHelper::Common
#
# @see AboutHelper
#
module AboutHelper::Common

  # Table cell display for blank/missing data.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  MISSING = '&mdash;'.html_safe.freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Lookup or generate a topic heading.
  #
  # @param [Symbol] topic
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def topic_heading(topic)
    default = "#{topic.to_s.humanize.capitalize} Codes"
    scope   = "blacklight.about.#{topic}"
    I18n.t('title', default: [:label, default], scope: scope).html_safe
  end

  # Wraps a name-value pair in <span> tags inside a paragraph element.
  #
  # @param [String]    name
  # @param [String]    value
  # @param [Hash, nil] opt
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]
  #
  def show_entry(name, value, opt = nil)
    html_opt = { class: 'about-entry' }
    merge_html_options!(html_opt, opt)
    name  = name.to_s
    value = value.inspect unless value&.html_safe?
    content_tag(:p, html_opt) {
      content_tag(:span, ERB::Util.h(name),  class: 'about-item') +
      content_tag(:span, ERB::Util.h(value), class: 'about-value')
    }
  end

  # Produces elements for a set of name-value pairs.
  #
  # @param [Hash]               table
  # @param [Array<String>, nil] featured
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def show_entries(table, featured = nil)
    table.map { |name, value|
      opt = ({ class: 'featured' } if featured&.include?(name))
      show_entry(name, value, opt)
    }.join("\n").html_safe
  end

end

__loading_end(__FILE__)
