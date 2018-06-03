# app/helpers/blacklight/catalog_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::CatalogHelperBehaviorExt
#
# @see Blacklight::CatalogHelperBehavior
#
# Some methods are overridden by:
# @see BlacklightAdvancedSearch::CatalogHelperOverrideExt
#
module Blacklight::CatalogHelperBehaviorExt

  include Blacklight::CatalogHelperBehavior
  include LensHelper

  # ===========================================================================
  # :section: Blacklight::CatalogHelperBehavior overrides
  # ===========================================================================

  public

  # Look up the current sort field, or provide the default if none is set.
  #
  # @return [Blacklight::Configuration::SortField]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_sort_field
  #
  def current_sort_field
    entry = nil
    sort_fields = blacklight_config.sort_fields
    [@response&.sort, params[:sort]].find { |sort|
      next if sort.blank?
      entry = sort_fields.find { |k, f| (k == sort) || (f.sort == sort) }
    }
    entry ||= sort_fields.first
    entry.last
  end

  # Get the classes to add to a document's div.
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_class
  #
  def render_document_class(doc = nil)
    render_document_classes(doc).join(' ').presence
  end

  # Render the sidebar partial for a document.
  #
  # @param [Blacklight::Document, nil] _doc    Unused.
  # @param [Hash, nil]                 locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_sidebar_partial
  #
  def render_document_sidebar_partial(_doc = nil, locals = nil)
    render_template('show_sidebar', locals)
  end

  # Render the main content partial for a document.
  #
  # @param [Blacklight::Document, nil] _doc    Unused.
  # @param [Hash, nil]                 locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_document_main_content_partial
  #
  def render_document_main_content_partial(_doc = nil, locals = nil)
    render_template('show_main_content', locals)
  end

  # Does the document have a thumbnail to render?
  #
  # @param [Blacklight::Document, nil] doc
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#has_thumbnail?
  #
  def has_thumbnail?(doc = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    view_cfg = index_view_config(doc)
    view_cfg.thumbnail_method.present? || doc.has?(view_cfg.thumbnail_field)
  end

  # Render the thumbnail, if available, for a document and link it to the
  # document record.
  #
  # @param [Blacklight::Document]  doc          Default: @document.
  # @param [Hash, nil]             image_opt    For #image_tag.
  # @param [Hash, FalseClass, nil] url_opt      For #link_to_document.
  #
  # @options url_opt [Boolean] :suppress_link   If *true* then just show the
  #                                               thumbnail image.
  #
  # @return [ActiveSupport::SafeBuffer, String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_thumbnail_tag
  #
  def render_thumbnail_tag(doc = nil, image_opt = nil, url_opt = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    image_opt ||= {}
    url_opt =
      if url_opt.is_a?(FalseClass)
        Deprecation.warn(self,
          'passing false as the second argument to render_thumbnail_tag is ' \
          'deprecated. Use suppress_link: true instead. This behavior will ' \
          'be removed in Blacklight 7'
        )
        { suppress_link: true }
      elsif url_opt.is_a?(Hash)
        url_opt.dup
      end
    url_opt ||= {}
    image =
      if (method = index_view_config(doc).thumbnail_method)
        send(method, doc, image_opt)
      elsif (url = thumbnail_url(doc))
        image_tag(url, image_opt)
      end
    suppress_link = url_opt.delete(:suppress_link) || image.blank?
    suppress_link ? image : link_to_document(doc, image, url_opt)
  end

  # Get the URL to a document's thumbnail image.
  #
  # @param [Blacklight::Document, nil] doc    Default: @document.
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#thumbnail_url
  #
  def thumbnail_url(doc = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    doc.first(index_view_config(doc).thumbnail_field)
  end

  # current_bookmarks
  #
  # @param [Blacklight::Solr::Response, nil] resp   Default: @response.
  #
  # @return [Array<Bookmark>]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_bookmarks
  #
  def current_bookmarks(resp = nil)
    @current_bookmarks ||=
      (resp ||= (@response if defined?(@response))) &&
      current_or_guest_user.bookmarks_for_documents(resp.documents).to_a
  end

  # Check if the document is in the user's bookmarks.
  #
  # @param [Blacklight::Document, nil]       doc    Default: @document.
  # @param [Blacklight::Solr::Response, nil] resp   Default: @response.
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#bookmarked?
  #
  def bookmarked?(doc = nil, resp = nil)
    bookmark_record(doc, resp).present?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get the configuration for a document's index view.
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Blacklight::Configuration::ViewConfig]
  #
  def index_view_config(doc = nil)
    blacklight_config(doc).view_config(document_index_view_type)
  end

  # Get the classes to add to a document's div.
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Array<String>]
  #
  def render_document_classes(doc = nil)
    doc ||= @document
    field = index_view_config(doc).display_type_field
    types = (doc[field] if doc.is_a?(Blacklight::Document))
    Array.wrap(types).map do |type|
      type = type.parameterize if type.respond_to?(:parameterize)
      "#{document_class_prefix}#{type}"
    end
  end

  # Get the record for the bookmark associated with *doc* if there is one.
  #
  # @param [Blacklight::Document, nil]       doc    Default: @document.
  # @param [Blacklight::Solr::Response, nil] resp   Default: @response.
  #
  # @return [Bookmark, nil]
  #
  def bookmark_record(doc = nil, resp = nil)
    doc ||= @document
    return unless doc.is_a?(Blacklight::Document)
    current_bookmarks(resp).find do |record|
      (record.document_id == doc.id) &&
        (record.document_type.to_s == doc.class.to_s)
    end
  end

  # rss_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def rss_button(options = nil)
    opt = { class: 'rss-link', title: 'RSS' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'fa fa-rss')
    url =
      opt.delete(:url) ||
      url_for(search_state.params_for_search(format: 'rss').except(:page))
    outlink(label, url, opt)
  end

  # atom_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def atom_button(options = nil)
    opt = { class: 'atom-link', title: 'Atom' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'fa fa-rss')
    url =
      opt.delete(:url) ||
      url_for(search_state.params_for_search(format: 'atom').except(:page))
    outlink(label, url, opt)
  end

  # print_view_button
  #
  # @param [Hash, nil] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def print_view_button(options = nil)
    opt = { class: 'print-view-link', title: 'Print view' }
    opt.merge!(options) if options.is_a?(Hash)
    label = opt.delete(:label) || ''
    label = content_tag(:div, label, class: 'glyphicon glyphicon-print')
    url   = opt.delete(:url)
    url ||= url_for(search_state.params_for_search(view: 'print'))
    outlink(label, url, opt)
  end

end

__loading_end(__FILE__)
