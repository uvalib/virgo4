# app/helpers/lens_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Methods supporting lens-specific display.
#
module LensHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # default_lens_controller
  # Must be overridden for non-lens controllers like BookmarksController.
  # NOTE: Just a trial...
  #
  # @param [Object] _scope            Currently unused.
  #
  # @return [Blacklight::Controller, nil]
  #
  def default_lens_controller(_scope = nil)
    result = self
    result = result.controller if result.respond_to?(:controller)
    if result.respond_to?(:default_catalog_controller)
      result.default_catalog_controller
    elsif result.class.respond_to?(:default_catalog_controller)
      result.class.default_catalog_controller
    elsif result.is_a?(Blacklight::Catalog)
      result
    end
  end

  # The current lens or the lens indicated by *object* if it is given.
  #
  # The method returns *nil* only when *object* does not map to a valid lens.
  #
  # @param [Object]                        object
  # @param [TrueClass, FalseClass, Symbol] default
  #
  # @raise [RuntimeError]             If the default lens is missing.
  #
  # @return [Blacklight::Lens::Entry]
  # @return [default] If *obj* is invalid and *default* is not a Boolean.
  # @return [nil]     If *obj* is invalid and *default* is *false*.
  #
  def lens_for(object, default = true)
    lens = nil
    trial_keys = [object]
    trial_keys <<
      case default
        when true  then default = current_lens_key
        when false then default = nil
        else            default
      end
    trial_keys.map! { |k| Blacklight::Lens.key_for(k, false) if k.present? }
    trial_keys.compact!
    trial_keys.uniq!
    trial_keys.find do |key|
      lens = Blacklight::Lens[key]
      lens ||=
        begin
          "config/#{key}".camelize.constantize.new # Instantiate configuration.
          Blacklight::Lens[key]
        end
    end
    if !lens && default
      raise("Blacklight::Lens.table has no entry for #{object || default}")
    end
    lens
  end

  # The current lens.
  #
  # If no lens can be determined for the current context, the result will be
  # Blacklight::Lens#default_lens.
  #
  # @return [Blacklight::Lens::Entry]
  #
  def current_lens
    lens_for(nil)
  end

  # The default lens.
  #
  # Returns *nil* if there is no default lens controller identifiable in the
  # current context.
  #
  # @return [Blacklight::Lens::Entry, nil]
  #
  def default_lens
    current_lens if default_lens_controller
  end

  # lens_key_for
  #
  # If no lens can be determined for the current context, the result will be
  # Blacklight::Lens#default_key.
  #
  # @param [Object]                        object
  # @param [TrueClass, FalseClass, Symbol] default
  #
  # @return [Symbol]
  #
  def lens_key_for(object, default = true)
    Blacklight::Lens.key_for(object, default)
  end

  # current_lens_key
  #
  # @return [Symbol]
  #
  def current_lens_key
    default_lens_controller&.lens_key || default_lens_key
  end

  # default_lens_key
  #
  # @return [Symbol]
  #
  def default_lens_key
    Blacklight::Lens.default_key
  end

  # blacklight_config
  #
  # @param [Object] object
  #
  # @return [Blacklight::Configuration]
  #
  def blacklight_config_for(object)
    lens_for(object).blacklight_config
  end

  # current_blacklight_config
  #
  # @return [Blacklight::Configuration]
  #
  def current_blacklight_config
    blacklight_config_for(nil)
  end

  # default_blacklight_config
  #
  # @return [Blacklight::Configuration]
  #
  def default_blacklight_config
    blacklight_config_for(default_lens_key)
  end

  # blacklight_config
  #
  # @param [Object, nil] lens         Default: `current_lens`.
  #
  # @return [Blacklight::Configuration]
  #
  def blacklight_config(lens = nil)
    blacklight_config_for(lens)
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
    [default_lens_controller&.controller_name, nil, default_lens_key.to_s].uniq
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

  # Maps lens to Bootstrap label color.
  LENS_COLOR_CLASS = {
    catalog:  'info',
    articles: 'warning',
    video:    'success',
    music:    'primary'
  }

  # A Bootstrap label used to identify the source lens of a history entry or
  # saved search.
  #
  # @param [Symbol, String] type      Lens type.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def search_type_label(type = nil)
    type ||= current_lens_key
    type_class = LENS_COLOR_CLASS[type]
    classes = ['label']
    classes << "label-#{type_class}" if type_class.present?
    classes << 'search-type'
    classes = classes.join(' ')
    content_tag(:div, type.capitalize, class: classes)
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
      when :catalog  then catalog_suggest_index_path(opt)
      when :articles then articles_suggest_index_path(opt)
      when :video    then video_suggest_index_path(opt)
      when :music    then music_suggest_index_path(opt)
    end
  end

end

__loading_end(__FILE__)
