# app/helpers/blacklight_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::BlacklightHelperBehavior
#
module BlacklightHelper

  include Blacklight::BlacklightHelperBehavior
  include BlacklightConfigurationHelper
  include BlacklightUrlHelper
  include HashAsHiddenFieldsHelper
  include LayoutHelper
  include IconHelper
  include ExportHelper
  include LensHelper

  def self.included(base)
    __included(base, '[BlacklightHelper]')
  end

  # The string added between the unique part of the page title and the common
  # portion of the page title.
  PAGE_TITLE_SEPARATOR = ' - '

  # ===========================================================================
  # :section: Blacklight::BlacklightHelperBehavior overrides
  # ===========================================================================

  public

  # Generate the page's HTML title, which appears in browser history and as the
  # browser tab label.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::BlacklightHelperBehavior#render_page_title
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

  # List of classes to be applied to the <body> element.
  #
  # @return [Array<String>]
  #
  # @see self#render_body_class
  #
  # This method overrides:
  # @see Blacklight::BlacklightHelperBehavior#extra_body_classes
  #
  def extra_body_classes
    @extra_body_classes ||= %W(
      blacklight-#{controller.controller_name}
      blacklight-#{controller.action_name}
      blacklight-#{controller.controller_name}-#{controller.action_name}
    )
  end

  # Render the index field label for a document
  #
  # Translations for index field labels should go under
  # blacklight.search.fields
  # They are picked up from there by a value "%{label}" in
  # blacklight.search.index.label
  #
  # @overload render_index_field_label(options)
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash] opt
  #
  #   @option opts [String] :field
  #
  # @overload render_index_field_label(document, options)
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opt
  #
  #   @option opts [String] :field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_index_field_label(*args)
    opt = args.extract_options!
    doc = args.first
    h(index_field_label(doc, opt[:field]))
  end

  # Render the show field label for a document
  #
  # @overload render_document_show_field_label(options)
  #   Use the default, document-agnostic configuration.
  #
  #   @param [Hash] opts
  #
  #   @option opts [String] :field
  #
  # @overload render_document_show_field_label(document, options)
  #   Allow an extension point where information in the document may drive the
  #   value of the field.
  #
  #   @param [Blacklight::Document] doc
  #   @param [Hash]                 opt
  #
  #   @option opts [String] :field
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def render_document_show_field_label(*args)
    opt = args.extract_options!
    doc = args.first
    h(document_show_field_label(doc, opt[:field]))
  end

  # show_presenter_class
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Class] (Blacklight::ShowPresenter or subclass)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#show_presenter_class
  #
  def show_presenter_class(doc = nil)
    blacklight_config_for(doc).show.document_presenter_class
  end

  # index_presenter_class
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Class] (Blacklight::IndexPresenter or subclass)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#index_presenter_class
  #
  def index_presenter_class(doc = nil)
    blacklight_config_for(doc).index.document_presenter_class
  end

  # search_bar_presenter_class
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Class] (Blacklight::SearchBarPresenter or subclass)
  #
  # This method replaces:
  # @see Blacklight::BlacklightHelperBehavior#search_bar_presenter_class
  #
  def search_bar_presenter_class(doc = nil)
    cfg = blacklight_config_for(doc)
    cfg.search_bar_presenter_class || cfg.index.search_bar_presenter_class
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

  # json_presenter
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Blacklight::JsonPresenter] (or subclass)
  #
  # == Implementation Notes
  # Defined for consistency.
  #
  def json_presenter(doc = nil)
    json_presenter_class(doc).new(doc, self)
  end

  # thumbnail_presenter
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Blacklight::ThumbnailPresenter] (or subclass)
  #
  # == Implementation Notes
  # Defined for consistency.
  #
  def thumbnail_presenter(doc = nil)
    view_type   = params[:show] ? :show : :index
    view_config = blacklight_config_for(doc || self).view_config(view_type)
    thumbnail_presenter_class(doc).new(doc, self, view_config)
  end

  # json_presenter_class
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Class] (Blacklight::JsonPresenter or subclass)
  #
  # == Implementation Notes
  # Defined for consistency.
  #
  def json_presenter_class(doc = nil)
    cfg = blacklight_config_for(doc)
    cfg.json_presenter_class ||
      Blacklight::Lens::JsonPresenter
  end

  # thumbnail_presenter_class
  #
  # @param [Blacklight::Document, nil] doc
  #
  # @return [Class] (Blacklight::ThumbnailPresenter or subclass)
  #
  # == Implementation Notes
  # Defined for consistency (currently set inside IndexPresenter).
  #
  def thumbnail_presenter_class(doc = nil)
    cfg = blacklight_config_for(doc)
    cfg.thumbnail_presenter_class ||
      cfg.index.thumbnail_presenter_class ||
      Blacklight::Lens::ThumbnailPresenter
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
  # @option opt [Boolean] :show_title           Default: *true*.
  # @option opt [Boolean] :show_subtitle        Default: *false*.
  # @option opt [Boolean] :show_author          Default: *false*.
  # @option opt [Boolean] :show_linked_author   Default: *false*.
  # @option opt [Boolean] :show_linked_author   Default: *false*.
  #
  # @return [String]
  #
  # @see Blacklight::Lens::ShowPresenter#heading
  #
  # Compare with:
  # @see Blacklight::BlacklightHelperBehavior#document_heading
  #
  def document_title(doc = nil, opt = nil)
    doc ||= @document
    config   = blacklight_config_for(doc)
    view_cfg = config.view_config(:show)
    options  = {
      format:             false,
      show_title:         !doc.has?(view_cfg.alt_title_field),
      show_subtitle:      false,
      show_author:        false,
      show_linked_author: false
    }
    options.merge!(opt) if opt.present?
    presenter(doc).heading(options)
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
