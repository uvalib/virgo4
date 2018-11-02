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
  # @param [Hash, nil]           opt    Path options.
  #
  # @return [String]
  #
  def document_path(lens = nil, opt = nil)
    if lens.is_a?(Hash)
      opt  = lens
      lens = nil
    else
      opt ||= {}
    end
    lens = Blacklight::Lens.key_for(lens, false) || current_lens_key
    case lens
      when :catalog  then catalog_path(opt)
      when :articles then articles_path(opt)
      when :video    then video_path(opt)
      when :music    then music_path(opt)
    end
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt    Path options.
  #
  # @return [String]
  #
  def search_path(lens = nil, opt = nil)
    if lens.is_a?(Hash)
      opt  = lens
      lens = nil
    else
      opt ||= {}
    end
    lens = Blacklight::Lens.key_for(lens, false) || current_lens_key
    case lens
      when :catalog  then search_catalog_path(opt)
      when :articles then search_articles_path(opt)
      when :video    then search_video_path(opt)
      when :music    then search_music_path(opt)
    end
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt    Path options.
  #
  # @return [String]
  #
  def advanced_search_path(lens = nil, opt = nil)
    if lens.is_a?(Hash)
      opt  = lens
      lens = nil
    else
      opt ||= {}
    end
    lens = Blacklight::Lens.key_for(lens, false) || current_lens_key
    case lens
      when :catalog  then catalog_advanced_search_path(opt)
      when :articles then articles_advanced_search_path(opt)
      when :video    then video_advanced_search_path(opt)
      when :music    then music_advanced_search_path(opt)
    end
  end

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt    Path options.
  #
  # @return [String]
  #
  def suggest_index_path(lens = nil, opt = nil)
    if lens.is_a?(Hash)
      opt  = lens
      lens = nil
    else
      opt ||= {}
    end
    lens = Blacklight::Lens.key_for(lens, false) || current_lens_key
    case lens
      when :catalog  then suggest_index_catalog_path(opt)
      when :articles then suggest_index_articles_path(opt)
      when :video    then suggest_index_video_path(opt)
      when :music    then suggest_index_music_path(opt)
    end
  end

end

__loading_end(__FILE__)
