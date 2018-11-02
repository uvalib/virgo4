# app/helpers/component_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::ComponentHelperBehavior
#
module ComponentHelper

  include Blacklight::ComponentHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[ComponentHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::ComponentHelperBehavior overrides
  # ===========================================================================

  public

  # document_action_label
  #
  # @param [Symbol, String]                                action
  # @param [Blacklight::Configuration::Field, String, nil] config
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#document_action_label
  #
  def document_action_label(action, config = nil)
    ctrl = (controller.controller_name if respond_to?(:controller))
    lens = current_lens_key
    keys = []
    keys << :"blacklight.#{ctrl}.tools.#{action}" if ctrl
    keys << :"blacklight.#{lens}.tools.#{action}" if lens
    keys << :"blacklight.tools.#{action}"
    keys << config.label if config.respond_to?(:label)
    keys << config       if config.is_a?(String)
    keys << action.to_s.humanize
    I18n.t(keys.shift, default: keys)
  end

  # document_action_path
  #
  # @param [Blacklight::Configuration::Field] action_opts
  # @param [Hash, nil]                        url_opts
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#document_action_path
  #
  def document_action_path(action_opts, url_opts = nil)
    url_opts = url_opts ? url_opts.symbolize_keys : {}
    url = helper = nil
    if action_opts.path.is_a?(String)
      url = action_opts.path
    elsif action_opts.path.is_a?(Symbol)
      helper = action_opts.path
    else
      action = action_opts.key
      target = ('document' if export_format.include?(action))
      target ||= url_opts[:controller] || current_lens_key
      helper = :"#{action}_#{target}_path"
    end
    url || send(helper, url_opts)
  end

  # Render "document actions" area for search results view.
  # (Normally renders next to title in the list view.)
  #
  # @param [Blacklight::Document] doc
  # @param [Hash, nil]            options
  #
  # @option options [String] :wrapping_class
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#render_index_doc_actions
  #
  def render_index_doc_actions(doc, options = nil)
    return unless doc.is_a?(Blacklight::Document)
    opt = { document: doc, wrapping_class: 'index-document-functions' }
    opt.merge!(options) if options.present?
    wrapper  = opt.delete(:wrapping_class)
    partials = index_view_config(doc).document_actions
    rendered = render_filtered_partials(partials, opt)
    content_tag(:div, rendered, class: wrapper) unless rendered.blank?
  end

  # Render "collection actions" area for search results view
  # (normally renders next to pagination at the top of the result set)
  #
  # @param [Hash] options
  #
  # @option options [String] :wrapping_class
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#render_results_collection_tools
  #
  def render_results_collection_tools(options = nil)
    opt = { wrapping_class: 'search-widgets' }
    opt.merge!(options) if options.present?
    wrapper  = opt.delete(:wrapping_class)
    partials = index_view_config.collection_actions
    rendered = render_filtered_partials(partials, opt)
    content_tag(:div, rendered, class: wrapper) unless rendered.blank?
  end

  # Render "document actions" for the item detail 'show' view.
  # (This normally renders next to title.)
  #
  # By default includes 'Bookmarks'
  #
  # @param [Blacklight::Document, nil] doc      Default: @document.
  # @param [Hash, nil]                 options
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#render_show_doc_actions
  #
  def render_show_doc_actions(doc = nil, options = nil, &block)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    opt = { document: doc }
    opt.merge!(options) if options.present?
    partials = blacklight_config_for(doc).show.document_actions
    render_filtered_partials(partials, opt, &block)
  end

  # show_doc_actions?
  #
  # @param [Blacklight::Document, nil] doc      Default: @document.
  # @param [Hash]                      options
  #
  # This method overrides:
  # @see Blacklight::ComponentHelperBehavior#show_doc_actions?
  #
  def show_doc_actions?(doc = nil, options = nil)
    render_show_doc_actions(doc, options).present?
  end

end

__loading_end(__FILE__)
