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

  # render_search_to_page_title
  #
  # @param [Hash] params
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_search_to_page_title
  #
  def render_search_to_page_title(params)
    constraints = []

    # Query
    if (q = params[:q]).present?

      # Surround with quotation marks if not already that way.
      q = %Q("#{q}") unless q =~ /^(["']).*\1$/

      # Add the query to the constraints, adding the search type if it's
      # different than the default search type.
      label =
        if (search_key = params[:search_field]).present?
          default_key = default_search_field&.fetch(:key, nil)
          label_for_search_field(search_key) unless search_key == default_key
        end
      constraints <<
        if label.present?
          t('blacklight.search.page_title.constraint', label: label, value: q)
        else
          q
        end
    end

    # Exclusive facets
    if (f = params[:f]).present?
      constraints +=
       f.to_unsafe_h.map { |k, v| render_search_to_page_title_filter(k, v) }
    end

    # Inclusive facets # TODO: Maybe this is adequate; maybe it isn't.
    if (f = params[:f_inclusive]).present?
      constraints +=
        f.to_unsafe_h.map { |k, v| render_search_to_page_title_filter(k, v) }
    end

    constraints.join(' / ')
  end

  # render_search_to_page_title_filter
  #
  # @param [Symbol, String] facet
  # @param [Array<String>]  values
  #
  # This method overrides:
  # @see Blacklight::CatalogHelperBehavior#render_search_to_page_title_filter
  #
  def render_search_to_page_title_filter(facet, values)
    scope = 'blacklight.search.page_title'
    cfg   = facet_configuration_for_field(facet)
    label = facet_field_label(cfg.key)
    value =
      if values.size < 3
        values.map { |value|
          '"' + facet_display_value(facet, value) + '"'
        }.to_sentence
      else
        t(:many_constraint_values, scope: scope, values: values.size)
      end
    t(:constraint, scope: scope, label: label, value: value)
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
  #
  # @see Blacklight::Rendering::HelperMethod#render_helper
  # ===========================================================================

  public

  # Configuration :helper_method for rendering :format_facet.
  #
  # For HTML response format only, it wraps each content format type in a
  # <span> for CSS styling.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [nil]                                 If no data was present.
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  #
  # @see ApplicationHelper#extract_config_value
  #
  # Compare with:
  # @see ArticlesHelper#eds_publication_type_label
  #
  def format_facet_label(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_html?(opt)
      result.map! { |v| content_tag(:span, v, class: 'label label-default') }
      result.join("&nbsp;\n").html_safe.presence
    elsif (result.size == 1) && !values.is_a?(Array)
      result.first
    else
      result
    end
  end

  # ===========================================================================
  # :section: Pre-release - TODO: remove when Virgo 3 is gone
  # ===========================================================================

  public

  # An outlink to the document in the current production Virgo 3 instance.
  #
  # @param [Blacklight::Lens::Document, Hash] doc
  # @param [Hash, nil]                        opt
  #
  # @option opt [String] :label       Link label in place of default.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # == Implementation Notes
  # Translating show pages is straightforward, however translating index pages
  # is problematic because the field names are all different.  Since that's a
  # lot of work for an unclear benefit, for now this method will simply return
  # *nil* from index pages.
  #
  def production_virgo_link(doc, opt = nil)
    return if params[:action] == 'index' # NOTE: see above
    html_opt = {
      label: 'In production Virgo',
      class: 'pre-release-button',
      title: 'View the equivalent record in Virgo 3 production'
    }
    merge_html_options!(html_opt, opt)
    label = html_opt.delete(:label)
    doc = doc.to_hash if params[:action] == 'index'
    url = production_virgo_url(doc)
    outlink(label, url, html_opt)
  end

  # The URL to the document in the current production Virgo 3 instance.
  #
  # @param [Blacklight::Lens::Document, Hash] opt
  #
  # == Usage Notes
  # The results of this method are only useful for item details show pages;
  # index pages would be useless because all of the facet field names are
  # different.  (To correct this, this method would have to process each URL
  # option, mapping Virgo 4 field names to Virgo 3 field names.)
  #
  def production_virgo_url(opt = nil)
    eds = doc = nil
    case opt
      when Blacklight::Document
        eds = opt.is_a?(Blacklight::Eds::Document)
        doc = opt
        opt = {}
      when ActionController::Parameters
        opt = opt.to_hash.with_indifferent_access
      when Hash
        opt = opt.with_indifferent_access
      else
        opt = {}
    end
    ctrlr  = opt.delete(:controller) || doc&.lens || default_lens_key
    action = opt.delete(:action).to_s
    if (action == 'show') || (action.blank? && doc)
      doc_id = opt.delete(:id) || doc&.export_id
      action = eds ? "article?id=#{doc_id}" : doc_id
    elsif (action == 'index') || (action.blank? && !doc)
      opt[:id] ||= doc.export_id if doc
      action = nil
    end

    url = +"https://search.lib.virginia.edu/#{ctrlr}"
    url << "/#{action}" if action.present?
    url << (action&.include?('?') ? '&' : '?') << opt.to_query if opt.present?
    url
  end

end

__loading_end(__FILE__)
