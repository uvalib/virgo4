# app/helpers/render_partials_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::RenderPartialsHelperBehavior
#
module RenderPartialsHelper

  include Blacklight::RenderPartialsHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[RenderPartialsHelper]')
  end

  # ===========================================================================
  # :section: Blacklight::RenderPartialsHelper overrides
  # ===========================================================================

  public

  # Render the document index for a grouped response.
  #
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelperBehavior#render_grouped_document_index
  #
  def render_grouped_document_index(locals = nil)
    render_template('group_default', locals)
  end

  # A list of document partial templates to attempt to render.
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelperBehavior#document_index_path_templates
  #
  def document_index_path_templates
    @document_index_path_templates ||=
      document_path_templates('document', %w(%{index_view_type} list))
    #
    # === In ArticlesController view:
    #
    # view_subdirs == ['articles', nil, 'catalog'] which yields:
    #
    #   articles/document_%{index_view_type}
    #   articles/document_list
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
    # === In CatalogController view:
    #
    # view_subdirs == [nil, 'catalog'] which yields:
    #
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
    # === In BookmarksController view:
    #
    # view_subdirs == [nil, 'catalog'] which yields:
    #
    #   document_%{index_view_type}
    #   document_list
    #   catalog/document_%{index_view_type}
    #   catalog/document_list
    #
  end

  # ===========================================================================
  # :section: Blacklight::RenderPartialsHelper overrides
  # ===========================================================================

  protected

  # Return a normalized partial name for rendering a single document.
  #
  # @param [Blacklight::Document] doc
  # @param [Symbol]               base_name   Base name for the partial.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelperBehavior#document_partial_name
  #
  def document_partial_name(doc, base_name = nil)
    view_cfg = blacklight_config_for(doc).view_config(:show)
    key  = base_name && view_cfg[:"#{base_name}_display_type_field"].presence
    type = (key && doc[key]) || doc[view_cfg.display_type_field] || 'default'
    type_field_to_partial_name(doc, type)
  end

  # A list of document partial templates to try to render for a document
  #
  # The partial names will be interpolated with the following variables:
  #   - action_name: (e.g. index, show)
  #   - index_view_type: (the current view type, e.g. list, gallery)
  #   - format: the document's format (e.g. book)
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see Blacklight::RenderPartialsHelperBehavior#document_partial_path_templates
  #
  def document_partial_path_templates
    @partial_path_templates ||=
      document_path_templates('%{action_name}', ['%{format}', nil])
    #
    # === In ArticlesController view:
    #
    # view_subdirs == ['articles', nil, 'catalog'] which yields:
    #
    #   articles/%{action_name}_%{format}
    #   articles/%{action_name}
    #   %{action_name}_%{format}
    #   %{action_name}
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}
    #
    # === In CatalogController view:
    #
    # view_subdirs == [nil, 'catalog'] which yields:
    #
    #   %{action_name}_%{format}
    #   %{action_name}
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}
    #
    # === In BookmarksController view:
    #
    # view_subdirs == [nil, 'catalog'] which yields:
    #
    #   %{action_name}_%{format}
    #   %{action_name}
    #   catalog/%{action_name}_%{format}
    #   catalog/%{action_name}
    #
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # document_path_templates
  #
  # @param [String]        base
  # @param [Array<String>] suffixes   One or more strings or arrays of strings
  #
  # @return [Array<String>]
  #
  # @see RenderPartialsHelper#document_partial_path_templates
  #
  def document_path_templates(base, *suffixes)
    suffixes.flatten!
    suffixes = [nil] if suffixes.empty?
    view_subdirs.flat_map do |view_subdir|
      view_subdir &&= "#{view_subdir}/"
      suffixes.map do |suffix|
        suffix &&= "_#{suffix}"
        "#{view_subdir}#{base}#{suffix}"
      end
    end
  end

end

__loading_end(__FILE__)
