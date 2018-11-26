# app/helpers/catalog_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::CatalogHelperBehavior
#
module CatalogHelper

  include Blacklight::CatalogHelperBehavior
  include BlacklightHelper
  include BlacklightConfigurationHelper
  include ComponentHelper
  include FacetsHelper
  include RenderConstraintsHelper
  include RenderPartialsHelper
  include ExportHelper
  include SearchHistoryConstraintsHelper

  def self.included(base)
    __included(base, '[CatalogHelper]')
  end

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
    [@response&.sort, params[:sort]].find do |sort|
      next if sort.blank?
      entry = sort_fields.find { |k, f| (k == sort) || (f.sort == sort) }
    end
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

  # Render the view type icon for the results view picker.
  #
  # @param [String] view
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_view_type_group_icon
  #
  # == Implementation Notes
  # If there is no SVG icon for the view, this method falls back on the logic
  # of the deprecated #default_view_type_group_icon_classes method to construct
  # a glyph.  (The method itself is not called to avoid deprecation warnings.)
  #
  def render_view_type_group_icon(view)
    blacklight_icon(view, raise: true)
  rescue Blacklight::Exceptions::IconNotFound
    view = view.to_s.parameterize
    content_tag(:span, '', class: "glyphicon-#{view} view-icon-#{view}")
  end

  # current_bookmarks
  #
  # @param [Array<Blacklight::Document>, Blacklight::Lens::Response, nil] docs
  #
  # @return [Array<Bookmark>]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#current_bookmarks
  #
  def current_bookmarks(docs = nil)
    @current_bookmarks ||=
      begin
        if docs.respond_to?(:documents)
          Deprecation.warn(
            Blacklight::CatalogHelperBehavior,
            'Passing a response to #current_bookmarks is deprecated; ' \
            'pass response.documents instead'
          )
          docs = docs.documents
        end
        docs ||= @document || @response&.documents
        current_or_guest_user.bookmarks_for(docs).to_a if docs.present?
      end
  end

  # Check if the document is in the user's bookmarks.
  #
  # @param [Blacklight::Document, nil] doc    Default: @document.
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#bookmarked?
  #
  def bookmarked?(doc = nil)
    bookmark_record(doc).present?
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
  # @param [Blacklight::Document, nil] doc    Default: @document.
  #
  # @return [Bookmark, nil]
  #
  def bookmark_record(doc = nil)
    doc ||= @document
    id = (doc.id if doc.is_a?(Blacklight::Document))
    current_bookmarks.find { |bookmark| bookmark.document_id == id } if id
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

  # Select the proper polymorphic search path based on the lens.
  #
  # @param [Symbol, String, nil] lens
  # @param [Hash, nil]           opt    Path options.
  #
  # @return [String]
  #
  # Duplicate of:
  # @see LensHelper#advanced_search_path
  #
  # @see LensHelper#lens_path
  #
  # TODO: Why is the LensHelper method not taking precedence over route helper?
  # It shouldn't be necessary to have this definition copied to here, but
  # without it app/catalog/_search_form.html.erb picks up the Rails route
  # helper definition rather than the override defined in LensHelper.
  #
  def advanced_search_path(lens = nil, opt = nil)
    lens_path('%s_advanced_search_path', lens, opt)
  end

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # format_facet_label
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # @see ArticlesHelper#eds_publication_type_label
  # @see Blacklight::Rendering::HelperMethod#render_helper
  #
  def format_facet_label(options = nil)
    return raw_value(options) unless request.format.html?
    values = (options[:value] if options.is_a?(Hash))
    values = Array.wrap(values).reject(&:blank?)
    return unless values.present?
    values.map { |value|
      content_tag(:span, value, class: 'label label-default')
    }.join("&nbsp;\n").html_safe
  end

end

__loading_end(__FILE__)
