# app/helpers/blacklight/blacklight_helper_behavior_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Blacklight::BlacklightHelperBehaviorExt
#
# Methods added to this helper will be available to all templates in the
# hosting application.
#
# This module is used in place of:
# @see Blacklight::BlacklightHelperBehavior
#
module Blacklight::BlacklightHelperBehaviorExt

  # Needed for RubyMine to indicate overrides.
  include Blacklight::BlacklightHelperBehavior unless ONLY_FOR_DOCUMENTATION

  include BlacklightUrlHelper
  include BlacklightConfigurationHelper
  include HashAsHiddenFieldsHelper
  include RenderConstraintsHelper
  include Blacklight::RenderPartialsHelperExt
  include FacetsHelper
  include LensHelper

  extend Deprecation
  self.deprecation_horizon = 'Blacklight version 7.0.0'

  # The string added between the unique part of the page title and the common
  # portion of the page title.
  PAGE_TITLE_SEPARATOR = ' - '

  # ===========================================================================
  # :section: Blacklight::BlacklightHelperBehavior replacements
  # ===========================================================================

  public

  # Get the name of this application from blacklight.en.yml.
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#application_name
  #
  def application_name
    t('blacklight.application_name')
  end

  # Generate the page's HTML title, which appears in browser history and as the
  # browser tab label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#application_name
  #
  def render_page_title
    page_name = current_page_title
    site_name = application_name.to_s
    if page_name.blank?
      site_name
    elsif page_name.end_with?(site_name)
      page_name
    elsif page_name.end_with?(PAGE_TITLE_SEPARATOR)
      page_name + site_name
    else
      page_name + PAGE_TITLE_SEPARATOR + site_name
    end
  end

  # Create <link rel="alternate"> links from a documents dynamically
  # provided export formats.
  #
  # Returns empty string if no links available.
  #
  # @param [Blacklight::Document] doc
  # @param [Hash]                 options
  #
  # @option options [Boolean] :unique ensures only one link is output for every
  #     content type, e.g. as required by atom
  # @option options [Array<String>] :exclude array of format shortnames to not
  #     include in the output
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_link_rel_alternates
  #
  def render_link_rel_alternates(doc = nil, options = nil)
    doc ||= @document
    presenter(doc).link_rel_alternates(options || {}) if doc
  end

  # Render OpenSearch headers for this search.
  #
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_opensearch_response_metadata
  #
  def render_opensearch_response_metadata(locals = nil)
    render_template('opensearch_response_metadata', locals)
  end

  # Render classes for the <body> element
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_body_class
  #
  def render_body_class
    extra_body_classes.join(' ')
  end

  # List of classes to be applied to the <body> element.
  #
  # @return [Array<String>]
  #
  # @see self#render_body_class
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#extra_body_classes
  #
  def extra_body_classes
    @extra_body_classes ||= %W(
      blacklight-#{controller.controller_name}
      blacklight-#{controller.action_name}
      blacklight-#{controller.controller_name}-#{controller.action_name}
    )
  end

  # Render the search navbar.
  #
  # @param [Hash, nil] locals
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_search_bar
  #
  def render_search_bar(locals = nil)
    render_template('search_form', locals)
  end

  # Indicate whether to render a given field in the index view.
  #
  # @param [Blacklight::Document]             doc
  # @param [Blacklight::Configuration::Field] field_def
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#should_render_index_field?
  #
  def should_render_index_field?(doc, field_def)
    document_has_value?(doc, field_def) && should_render_field?(field_def, doc)
  end

  # Indicate whether to render a given field in the show view.
  #
  # @param [Blacklight::Document]             doc
  # @param [Blacklight::Configuration::Field] field_def
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#should_render_show_field?
  #
  def should_render_show_field?(doc, field_def)
    document_has_value?(doc, field_def) && should_render_field?(field_def, doc)
  end

  # Indicate whether a document has (or, might have, in the case of accessor
  # methods) a value for the given Solr field.
  #
  # @param [Blacklight::Document]             doc
  # @param [Blacklight::Configuration::Field] field_def
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#document_has_value?
  #
  def document_has_value?(doc, field_def)
    doc.has?(field_def.field) || field_def.accessor ||
      (field_def.highlight && doc.has_highlight_field?(field.field_def))
  end

  # Indicate whether to display spellcheck suggestions.
  #
  # @param [Blacklight::Solr::Response] response
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#should_show_spellcheck_suggestions?
  #
  def should_show_spellcheck_suggestions?(response)
    (response.total <= spell_check_max) && response.spelling.words.any?
  end

  # Render the index field label for a document
  #
  # @overload render_index_field_label(opts)
  #
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #
  # @overload render_index_field_label(doc, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_index_field_label
  #
  def render_index_field_label(*args)
    opt = args.extract_options!
    doc = args.first
    html_escape t(
      "blacklight.search.index.#{document_index_view_type}.label",
      label:   index_field_label(doc, opt[:field]),
      default: :'blacklight.search.index.label',
    )
  end

  # Render the index field label for a document
  #
  # @overload render_index_field_value(opts)
  #
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #   @option opts [String] :value
  #   @option opts [String] :document
  #
  # @overload render_index_field_value(doc, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #   @option opts [String] :value
  #
  # @overload render_index_field_value(doc, field, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [String]               field
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :value
  #
  # @deprecated Use IndexPresenter#field_value
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_index_field_value
  #
  def render_index_field_value(*args)
    render_field_value(*args)
  end
  deprecate render_index_field_value: 'replaced by IndexPresenter#field_value'

  # render_field_value
  #
  # @deprecated Use IndexPresenter#field_value
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_field_value
  #
  def render_field_value(*args)
    opt = args.last.is_a?(Hash) ? args.last.dup : {}
    doc = opt.delete(:document)
    fld = opt.delete(:field)
    doc = args.shift || doc
    fld = args.shift || fld
    presenter(doc).field_value(fld, opt)
  end
  deprecate render_field_value: 'replaced by IndexPresenter#field_value'

  # Render the show field label for a document
  #
  # @overload render_document_show_field_label(opts)
  #
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash] opts
  #
  #   @option opts [String] :field
  #
  # @overload render_document_show_field_label(doc, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_document_show_field_label
  #
  def render_document_show_field_label(*args)
    opt = args.extract_options!
    doc = args.first
    fld = opt[:field]
    lbl = document_show_field_label(doc, fld)
    t('blacklight.search.show.label', label: lbl)
  end

  # Render the index field label for a document
  #
  # @overload render_document_show_field_value(opts)
  #
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash] opts
  #
  #   @option opts [String] :field
  #   @option opts [String] :value
  #   @option opts [String] :document
  #
  # @overload render_document_show_field_value(doc, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :field
  #   @option opts [String] :value
  #
  # @overload render_document_show_field_value(doc, field, opts)
  #
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [String]               field
  #   @param [Hash]                 opts
  #
  #   @option opts [String] :value
  #
  # @deprecated Use ShowPresenter#field_value
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_document_show_field_value
  #
  def render_document_show_field_value(*args)
    render_field_value(*args)
  end
  deprecate render_document_show_field_value:
    'replaced by ShowPresenter#field_value'

  # Get the value of the document's "title" field or a placeholder value.
  #
  # @param [Blacklight::Document] doc   Default: @document.
  # @param [Hash, nil]            opt
  #
  # @return [String]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#document_heading
  #
  def document_heading(doc = nil, opt = nil)
    doc ||= @document
    presenter(doc).heading(opt)
  end

  # Get the document's "title" to display in the <title> element.
  # (by default, use the #document_heading)
  #
  # @param [Blacklight::Document] doc   Default: @document.
  # @param [Hash, nil]            opt
  #
  # @return [String]
  #
  # @see self#document_heading
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#document_show_html_title
  #
  def document_show_html_title(doc = nil, opt = nil)
    doc ||= @document
    presenter(doc).html_title(opt)
  end

  # Render the document "heading" (title) in a content tag.
  #
  # @overload render_document_heading(doc, opts)
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opts
  #
  #   @option opts [Symbol] :tag
  #   @option opts [Symbol] :title_tag
  #   @option opts [Symbol] :author_tag
  #
  # @overload render_document_heading(opts)
  #
  #   @param [Hash]                 opts
  #
  #   @option opts [Symbol] :tag
  #   @option opts [Symbol] :title_tag
  #   @option opts [Symbol] :author_tag
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_document_heading
  #
  def render_document_heading(*args)
    opt = args.last.is_a?(Hash) ? args.pop.dup : {}
    doc = args.first
    tag = opt.delete(:tag)
    opt[:title_tag] ||= tag || true
    document_heading(doc, opt).html_safe
  end

  # Get the value for a document's field, and prepare to render it.
  # - highlight_field
  # - accessor
  # - solr field
  #
  # Rendering:
  #   - helper_method
  #   - link_to_search
  #
  # @param [Blacklight::Document]             doc
  # @param [String]                           _field_name
  # @param [Blacklight::Configuration::Field] field_def
  # @param [Hash]                             options
  #
  # @deprecated
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#get_field_values
  #
  def get_field_values(doc, _field_name, field_def, options = nil)
    options ||= {}
    presenter(doc).field_values(field_def, options)
  end
  deprecate :get_field_values

  # Get the current "view type" (and ensure it is a valid type).
  #
  # @param [ActionController::Parameters, Hash, nil] query_params
  #
  # @return [Symbol]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#document_index_view_type
  #
  def document_index_view_type(query_params = nil)
    query_params ||= params
    view_param = query_params[:view] || session[:preferred_view]
    view_param &&= view_param.to_sym
    if document_index_views.key?(view_param)
      view_param
    else
      default_document_index_view_type
    end
  end

  # Render a partial of an arbitrary format inside a template of a different
  # format. (e.g. render an HTML partial from an XML template).
  #
  # @param [String] format suffix
  #
  # @yield
  #
  # Code taken from:
  # @see http://stackoverflow.com/questions/339130/how-do-i-render-a-partial-of-a-different-format-in-rails (zgchurch)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#with_format
  #
  def with_format(format, &block)
    old_formats = formats
    self.formats = [format]
    yield
    self.formats = old_formats
    nil
  end

  # Should we render a grouped response (because the response contains a
  # grouped response instead of the normal response).
  #
  # @param [Blacklight::Solr::Response] response
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#render_grouped_response?
  #
  def render_grouped_response?(response = nil)
    response ||= @response
    response&.grouped?
  end

  # A document presenter for the given document.
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Blacklight::IndexPresenterExt]
  # @return [Blacklight::ShowPresenterExt]
  # @return [Blacklight::DocumentPresenter]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#presenter
  #
  def presenter(doc)
    case action_name
      when 'show', 'citation' then return show_presenter(doc)
      when 'index'            then return index_presenter(doc)
    end
    Deprecation.warn(
      Blacklight::BlacklightHelperBehaviorExt,
      "Unable to determine presenter type for #{action_name} on " \
      "#{controller_name}, falling back on " \
      "deprecated Blacklight::DocumentPresenter"
    )
    presenter_class.new(doc, self)
  end

  # show_presenter
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Blacklight::ShowPresenterExt]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#show_presenter
  #
  def show_presenter(doc)
    show_presenter_class(doc).new(doc, self)
  end

  # index_presenter
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Blacklight::IndexPresenterExt]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#index_presenter
  #
  def index_presenter(doc)
    index_presenter_class(doc).new(doc, self)
  end

  # presenter_class
  #
  # @return [Class] (Blacklight::DocumentPresenter)
  #
  # @deprecated Use self#show_presenter_class or self#index_presenter_class
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#presenter_class
  #
  def presenter_class
    blacklight_config.document_presenter_class
  end
  deprecate presenter_class:
    'replaced by show_presenter_class/index_presenter_class'

  # Override this method if you want to use a different presenter class.
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Class] (Blacklight::ShowPresenterExt)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#show_presenter_class
  #
  def show_presenter_class(doc)
    blacklight_config(doc).show.document_presenter_class
  end

  # index_presenter_class
  #
  # @param [Blacklight::Document] doc
  #
  # @return [Class] (Blacklight::IndexPresenterExt)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#index_presenter_class
  #
  def index_presenter_class(doc)
    blacklight_config(doc).index.document_presenter_class
  end

  # Open Search discovery tag for HTML <head> links.
  #
  # @param [String, nil] title        Default: `application_name`.
  # @param [String, nil] href         Default: `opensearch_url`.
  # @param [String, nil] mime_type
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#opensearch_description_tag
  #
  def opensearch_description_tag(title = nil, href = nil, mime_type = nil)
    title     ||= application_name
    href      ||= opensearch_url(format: 'xml')
    mime_type ||= 'application/opensearchdescription+xml'
    tag(:link, href: href, title: title, type: mime_type, rel: 'search')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The current value of the page title (for browser history and browser tabs).
  #
  # @return [String]
  #
  # == Implementation Notes
  # Note that `content_for(:page_title)` trumps @page_title.
  #
  def current_page_title
    (content_for(:page_title) || @page_title).to_s
  end

  # Indicate whether the page has a title.
  #
  # == Usage Notes
  # For use within partial templates that may supply a default title if no
  # title had been specified by earlier templates.
  #
  def has_page_title?
    current_page_title.present?
  end

  # Get the value of the document's "title" field or a placeholder value.
  #
  # @param [Blacklight::Document] doc   Default: @document.
  # @param [Hash, nil]            opt
  #
  # @option opt [Boolean] :format               Default: *false*.
  # @option opt [Boolean] :show_title           Default: *false*.
  # @option opt [Boolean] :show_subtitle        Default: *false*.
  # @option opt [Boolean] :show_authors         Default: *false*.
  # @option opt [Boolean] :show_linked_authors  Default: *false*.
  #
  # @return [String]
  #
  # Compare with:
  # @see Blacklight::BlacklightHelperBehavior#document_heading
  #
  def document_title(doc = nil, opt = nil)
    doc ||= @document
    opt = opt ? opt.dup : {}
    config   = blacklight_config(doc)
    view_cfg = config.view_config(:show)
    opt[:format]              = false unless opt.key?(:format)
    opt[:show_title]          = false if doc.has?(view_cfg.alt_title_field)
    opt[:show_subtitle]       = false
    opt[:show_authors]        = false
    opt[:show_linked_authors] = false
    presenter(doc).heading(opt)
  end

  # Generate a value that can be used for the :id attribute of an HTML element.
  #
  # @param [Blacklight::Document] doc   Default: @document.
  #
  # @return [String, nil]
  #
  def document_id(doc = nil)
    doc ||= @document
    'doc_' + doc.id.to_s.parameterize if doc
  end

end

__loading_end(__FILE__)
