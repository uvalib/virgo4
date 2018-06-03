# app/helpers/blacklight/component_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight

  # Blacklight::ComponentHelperBehaviorExt
  #
  # @see Blacklight::ComponentHelperBehavior
  #
  module ComponentHelperBehaviorExt

    include Blacklight::ComponentHelperBehavior
    include LensHelper

    # =========================================================================
    # :section: Blacklight::ComponentHelperBehavior overrides
    # =========================================================================

    public

    # document_action_path
    #
    # @param [?]         action_opts
    # @param [Hash, nil] url_opts
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#document_action_path
    #
    def document_action_path(action_opts, url_opts = nil)
      url_opts ||= {}
      if action_opts.path
        self.send(action_opts.path, url_opts)
      elsif (id = url_opts[:id]).class.respond_to?(:model_name)
        url_for(controller: current_lens_key, action: action_opts.key, id: id)
      else
        controller = default_lens_controller.controller_name
        url_helper = "#{action_opts.key}_#{controller}_path"
        self.send(url_helper, url_opts)
      end
    end

    # Render "document actions" area for search results view.
    # (Normally renders next to title in the list view.)
    #
    # @param [Blacklight::Document, nil] doc      Default: @document.
    # @param [Hash, nil]                 options
    #
    # @option options [String] :wrapping_class
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_index_doc_actions
    #
    def render_index_doc_actions(doc = nil, options = nil)
      doc ||= @document
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
      opt = { wrapping_class: 'search-widgets pull-right' }
      opt.merge!(options) if options.present?
      wrapper  = opt.delete(:wrapping_class)
      partials = index_view_config.collection_actions
      rendered = render_filtered_partials(partials, opt)
      content_tag(:div, rendered, class: wrapper) unless rendered.blank?
    end

    # render_filters_partials
    #
    # @param [Blacklight::NestedOpenStructWithHashAccess] partials
    # @param [Hash]                                       options
    #
    # @yield [config, ActiveSupport::SafeBuffer]
    #
    # @return [ActiveSupport::SafeBuffer, nil]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#render_filtered_partials
    #
    def render_filtered_partials(partials, options = nil)
      opt = {}
      opt.merge!(options) if options.is_a?(Hash)
      content = []
      filter_partials(partials, opt).each do |key, config|
        config.key ||= key
        partial  = config.partial || key.to_s
        locals   = opt.merge(document_action_config: config)
        rendered = render(partial, locals)
        next unless rendered
        if block_given?
          yield config, rendered
        else
          content << rendered
        end
      end
      safe_join(content, "\n") unless block_given?
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
      partials = blacklight_config(doc).show.document_actions
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

    # =========================================================================
    # :section: Blacklight::ComponentHelperBehavior overrides
    # =========================================================================

    private

    # filter_partials
    #
    # @param [Blacklight::NestedOpenStructWithHashAccess] partials
    # @param [Hash]                                       options
    #
    # @return [Hash]
    #
    # This method overrides:
    # @see Blacklight::ComponentHelperBehavior#filter_partials
    #
    def filter_partials(partials, options)
      context = blacklight_configuration_context
      partials.select do |_, config|
        context.evaluate_if_unless_configuration(config, options)
      end
    end

  end

end

__loading_end(__FILE__)
