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
  # app/assets/images/blacklight/*.svg.
  #
  # @param [String, Symbol] icon_name
  # @param [Hash, nil]      opt
  #
  # @option opt [Boolean] :raise      If *false*, return *nil* if not found.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::IconHelperBehavior#blacklight_icon
  #
  def blacklight_icon(icon_name, opt = nil)
    opt = opt ? opt.dup : {}
    result =
      if opt.delete(:raise)
        super(icon_name, opt)
      else
        super(icon_name, opt) rescue nil
      end
    return result if result.present?
    icon_name = icon_name.to_s.sub(/^glyphicon-/, '')
    content_tag(:span, '', class: "glyphicon glyphicon-#{icon_name}")
  end

end

__loading_end(__FILE__)
