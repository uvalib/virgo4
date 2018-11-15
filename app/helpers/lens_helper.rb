# app/helpers/lens_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Methods supporting lens-specific display.
#
module LensHelper

  include Blacklight::Lens

  def self.included(base)
    __included(base, '[LensHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The list of view subdirectories.
  #
  # @return [Array<String, nil>]
  #
  def view_subdirs
    subdirs = [
      current_lens_key,
      nil,
      Blacklight::Lens.default_lens_key.to_s
    ]
    subdirs.uniq
  end

  # Render with optional local values.
  #
  # @param [String]    partial        Base partial name.
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # @see ActionView::Helpers::RenderingHelper#render
  #
  def render_template(partial, locals = nil)
    locals ||= {}
    render(partial, locals)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A Bootstrap label used to identify the source lens of a history entry or
  # saved search.
  #
  # @param [Symbol, String] type      Lens type.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_type_label(type = nil)
    type ||= current_lens_key
    css_classes = "label #{type}-search"
    content_tag(:div, type.capitalize, class: css_classes)
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt
  #
  # @return [String]
  #
  # @see LensHelper#lens_path
  #
  def document_path(lens = nil, opt = nil)
    lens_path('%s_path', lens, opt)
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt
  #
  # @return [String]
  #
  # @see LensHelper#lens_path
  #
  def search_path(lens = nil, opt = nil)
    lens_path('search_%s_path', lens, opt)
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt
  #
  # @return [String]
  #
  # @see LensHelper#lens_path
  #
  def advanced_search_path(lens = nil, opt = nil)
    lens_path('%s_advanced_search_path', lens, opt)
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt
  #
  # @return [String]
  #
  # @see LensHelper#lens_path
  #
  def suggest_index_path(lens = nil, opt = nil)
    lens_path('suggest_index_%s_path', lens, opt)
  end

  # Generate a route path from a template and a lens.
  #
  # @param [String] base                The route name template; if it contains
  #                                       "%s" then the lens is inserted at
  #                                       that point; otherwise "#{lens}_" is
  #                                       prepended to the template.
  #
  # @param [Symbol, String, nil] lens   If *nil*, opt[:lens] is used, else
  #                                       `current_lens_key` is used.
  #
  # @param [Hash, nil] opt              Options passed to the route helper
  #                                       (except for the options below).
  #
  # @options opt [Symbol,String] :lens  This will be removed and used as then
  #                                       the lens value if present.
  #
  # @options opt [Boolean] :only_path   If *false* then the result is a full
  #                                       URL rather than a relative path.
  #
  # @return [String]
  #
  def lens_path(base, lens = nil, opt = nil)
    if lens.is_a?(Hash)
      opt  = lens
      lens = nil
    end
    opt    = opt ? opt.dup : {}
    lens ||= opt.delete(:lens)
    lens   = Blacklight::Lens.key_for(lens, false) || current_lens_key
    path   = base.include?('%') ? (base % lens) : "#{lens}_#{base}"
    extent = opt.delete(:only_path).is_a?(FalseClass) ? '_url' : '_path'
    path.sub!(/(_path|_url)?$/, extent) unless path.end_with?(extent)
    send(path, opt)
  end

end

__loading_end(__FILE__)
