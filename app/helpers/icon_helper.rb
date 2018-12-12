# app/helpers/icon_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::IconHelperBehavior
#
module IconHelper

  include Blacklight::IconHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[IconHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::IconHelperBehavior overrides
  # ===========================================================================

  public

  # Returns the raw SVG (String) for a cached Blacklight icon located in
  # app/assets/images/blacklight/*.svg.  If no icon is found, a glyphicon is
  # attempted.
  #
  # @param [String, Symbol] icon_name
  # @param [Hash, nil]      opt
  #
  # @option opt [Boolean] :raise      If *true*, use the overridden Blacklight
  #                                     method directly unless the icon is
  #                                     clearly a glyphicon.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::IconHelperBehavior#blacklight_icon
  #
  # == Implementation Notes
  # There are not many SVG icons so this method attempts to create a glyph
  #
  def blacklight_icon(icon_name, opt = nil)
    opt = opt ? opt.dup : {}
    no_raise  = !opt.delete(:raise)
    icon_name = icon_name.to_s
    result =
      unless icon_name.start_with?('glyphicon-')
        no_raise ? (super(icon_name, opt) rescue nil) : super(icon_name, opt)
      end
    if result.blank?
      icon_name = icon_name.sub(/^glyphicon-/, '')
      merge_html_options!(opt, class: "glyphicon glyphicon-#{icon_name}")
      result = content_tag(:span, '', opt)
    end
    result
  end

end

__loading_end(__FILE__)
