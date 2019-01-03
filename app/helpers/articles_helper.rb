# app/helpers/articles_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Methods to support the display of EdsDocument items.
#
# == Usage Notes
# For each method *options* will be a Hash with the following contents:
#
#   {
#     document: EdsDocument.instance,
#     field:    String,                               # name of matched field (e.g. 'eds_all_links')
#     config:   Blacklight::Configuration::ShowField, # instance for matched field
#     value:    Array                                 # Array<Hash>
#   }
#
module ArticlesHelper

  include BlacklightHelper
  include ArticlesHelper::FullText

  def self.included(base)
    __included(base, '[ArticlesHelper]')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # "Find @ UVA" link label.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  EDS_LINK_LABEL = I18n.t('ebsco_eds.links.eds').html_safe.freeze

  # "PLink" label.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  EDS_PLINK_LABEL = I18n.t('ebsco_eds.links.plink').html_safe.freeze

  # URL anchor location on the page for the full text viewer.
  #
  # @type [String]
  #
  FULL_TEXT_ANCHOR = 'full-text'

  # Displayed only if a method is set up to avoid returning *nil*.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  # @see self#return_empty
  #
  EBSCO_NO_LINK = I18n.t('blacklight.no_link').html_safe.freeze

  # Indicate whether a method should return *nil* if there was no data.
  # If *false* then self#EBSCO_NO_LINK is returned.
  #
  # @type [Hash{Symbol=>Boolean}]
  #
  # @see self#return_empty
  #
  RETURN_NIL = {
    best_fulltext:              false,
    eds_all_links:              false,
    eds_plink:                  true,
    eds_publication_type_label: true,
  }.freeze

  # Types of linked content.
  #
  # @type [Array<String>]
  #
  EBSCO_LINK_TARGETS = %w(pdf ebook-pdf ebook-epub html cataloglink).freeze

  # Alter the order of the types listed below, putting the most desired links
  # first.
  #
  # @type [Array<String>]
  #
  BEST_FULLTEXT_TYPES = %w(
    cataloglink
    pdf
    ebook-pdf
    ebook-epub
    smartlinks
    customlink-fulltext
    customlink-other
  ).freeze

  # ===========================================================================
  # :section: Blacklight configuration "helper_methods"
  # ===========================================================================

  public

  # Configuration :helper_method for rendering :eds_publication_type.
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
  # @see CatalogHelper#format_facet_label
  #
  def eds_publication_type_label(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_non_html?(opt)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      separator = opt[:separator] || "<br/>\n"
      result.map! { |v| content_tag(:span, v, class: 'label label-default') }
      result.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # Configuration :helper_method for rendering :eds_composed_title.
  #
  # For HTML response format only, if the value of :eds_composed_title (from
  # `options[:value]`) is blank then :eds_publication_date is used.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  # @see ApplicationHelper#extract_config_value
  #
  # TODO: This never gets triggered if :eds_composed_title is missing...
  # Maybe dealing with fields in this way needs to be handled through
  # IndexPresenter.
  #
  def eds_index_publication_info(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_html?(opt)
      separator = opt[:separator] || "<br/>\n"
      if result.blank? && (doc = opt[:document]).is_a?(Blacklight::Document)
        result = Array.wrap(doc['eds_publication_date']).reject(&:blank?)
      end
      result.join(separator).html_safe.presence
    else
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    end
  end

  # Configuration :helper_method for rendering :eds_abstract.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  # @see ApplicationHelper#extract_config_value
  #
  # == Description
  # Although in many cases it is simple text -- in general, the content of this
  # EBSCO EDS field is an HTML fragment, meaning that it may contain HTML
  # entities ('&amp;lt;', '&amp;nbsp;', etc) as well as elements like
  # '&lt;b&gt;', '&lt;i&gt;', etc.
  #
  # Abstracts from some publishers contain implied sections where the
  # "subheading" appears either as:
  #
  #   (1) A single word and a colon following a break ("<br>");
  #   (2) A single uppercase word and a colon optionally following a '*'.
  #   (2) A single word and a colon enclosed in a bold ("&lt;b&gt;") element.
  #
  # This method makes these explicit by wrapping these in a :div with class
  # "subheading" for CSS styling.
  #
  # Because this field is fundamentally HTML, this method is applied equally
  # regardless of the response format (HTML or otherwise).
  #
  # == Usage Notes
  # This method is applied equally regardless of the response format (HTML or
  # otherwise).  For JSON response format, the URL parameter "&raw=true" can be
  # used to obtain the original value of field.
  #
  # == Examples
  #
  # @example With implied sections after <br>
  #   /articles/cmedm__30552144
  #
  # @example With implied sections within <b>
  #   /articles/a9h__133419289
  #
  def eds_abstract(options = nil)
    values, opt = extract_config_value(options)
    separator = opt[:separator] || "<br/>\n"
    result = Array.wrap(values).reject(&:blank?).join(separator)

    # === Insert breaks before bullets
    result.gsub!(EBSCO_BREAK_BEFORE_REGEX, '<br/>\1 ')

    # === Make implied sections explicit
    if result.gsub!(%r{<br\s*/?>([^:\s]+:)\s*}) { abstract_subsection($1) }
      # (1) For implied sections that follow a <br>, the first implied section
      # will be at the start of the abstract without a <br>.
      result.sub!(/\A([^:\s]+:)\s*/) { abstract_subsection($1) }
    elsif result.gsub!(%r{(\*?\s*)([A-Z]{3,}\s*:)}) { abstract_subsection($2) }
      # (2)
    else
      # (3) Handle implied sections within <b>.
      result.gsub!(/<b>\s*([^:<]*:)\s*<\/b>/) { abstract_subsection($1) }
    end

    # === Eliminate leading and trailing breaks
    result.sub!(%r{^\s*(</?\s*br\s*/?\s*>\s*)+}i, '')
    result.sub!(%r{(</?\s*br\s*/?\s*>\s*)+\s*$}i, '')

    if rendering_html?(opt)
      result.html_safe.presence
    else
      result = result.split(separator)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    end
  end

  # best_fulltext
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  # @see ApplicationHelper#extract_config_value
  #
  # TODO: This :helper_method needs to be revisited...
  #
  def best_fulltext(options = nil)
    values, opt = extract_config_value(options)
    values = (values.first.presence if values.is_a?(Hash))
    controller = 'articles' # TODO: generalize
    separator  = opt[:separator]
    raw        = opt[:raw] || rendering_non_html?(opt)
    id         = values['id'].to_s.tr('.', '_')
    result = (values['links'].to_a if values.is_a?(Hash))
    result &&=
      BEST_FULLTEXT_TYPES.map { |type|
        hash = result.find { |hash| hash['type'] == type }
        url  = hash && hash['url']
        next unless url.present?
        # Use the new fulltext route and controller to avoid time-bombed PDF
        # links.
        pdf = %w(pdf ebook-pdf).include?(type)
        url = "/#{controller}/#{id}/#{type}/fulltext" if pdf
        # Replace 'URL' label for catalog links.
        label = (type == 'cataloglink') ? 'Catalog Link' : hash['label']
        label = 'Full Text' if label.blank?
        make_eds_link(label: label, url: url, raw: raw)
      }.compact
    if raw
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      result.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # Configuration :helper_method for rendering :eds_html_fulltext.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [String]                              If request.format.json?
  #
  # @see ArticlesHelper::FullText#render_fulltext
  # @see ApplicationHelper#extract_config_value
  #
  # == Usage Notes
  # This method is applied equally regardless of the response format (HTML or
  # otherwise).  For JSON response format, the URL parameter "&raw=true" can be
  # used to obtain the original value of field.
  #
  def eds_html_fulltext(options = nil)
    values, opt = extract_config_value(options)
    content = render_fulltext(values, opt)
    if rendering_html?(opt)
      anchor   = content_tag(:div, '', id: FULL_TEXT_ANCHOR, class: 'anchor')
      scroller = content_tag(:div, content.html_safe, class: 'scroller')
      anchor + scroller
    else
      content.to_str
    end
  end

  # Configuration :helper_method for rendering :eds_html_fulltext_available.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  def eds_html_fulltext_link(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    return unless result.present? && (doc = opt[:document])
    label = I18n.t('ebsco_eds.links.view', default: 'View')
    url =
      url_for(
        controller: Blacklight::Lens.key_for_doc(doc),
        action:     :show,
        id:         doc.id,
        anchor:     FULL_TEXT_ANCHOR
      )
    make_eds_link(label: label, url: url)
  end

  # Configuration :helper_method for rendering :eds_plink.
  #
  # For HTML response format only, the URL is rendered as a link.  (There
  # should only be one :eds_plink value.)
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  def eds_plink(options = nil)
    values, opt = extract_config_value(options)
    result = Array.wrap(values).reject(&:blank?)
    if rendering_non_html?(opt)
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      outlink(EDS_PLINK_LABEL, result.first)
    else
      return_empty(__method__)
    end
  end

  # Configuration :helper_method for rendering :eds_all_links.
  #
  # For HTML response format only, the URLs are rendered as links.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [Array<ActiveSupport::SafeBuffer>]    If request.format.html?
  # @return [ActiveSupport::SafeBuffer]           If request.format.html?
  # @return [Array<String>]                       If request.format.json?
  # @return [String]                              If request.format.json?
  # @return [nil]                                 If no data was present.
  #
  def eds_all_links(options = nil)
    values, opt = extract_config_value(options)
    non_html = rendering_non_html?(opt)
    types    = opt.delete(:type)
    result =
      Array.wrap(values).reject(&:blank?).map { |value|
        hash = value.is_a?(Hash) ? value.symbolize_keys : { url: value }
        next unless types.blank? || types.include?(value[:type])
        hash.except(:expires).merge(raw: non_html)
      }.compact
    if non_html
      result.map! { |hash| make_eds_link(**hash) }
      (values.is_a?(Array) || (result.size > 1)) ? result : result.first
    elsif result.present?
      separator = opt[:separator] || "<br/>\n"
      result.map { |hash| make_eds_link(**hash) }.join(separator).html_safe
    else
      return_empty(__method__)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Should the current be user as treated unauthorized?
  #
  def eds_guest?
    current_or_guest_user.guest
  end

  # make_eds_link
  #
  # @param [String]          label
  # @param [String]          url
  # @param [String]          icon
  # @param [Boolean]         raw
  # @param [Boolean, String] guest
  # @param [String]          type
  # @param [String]          separator    Ignored.
  # @param [Hash]            opt
  #
  # @return [ActiveSupport::SafeBuffer]   If request.format.html?
  # @return [String]                      If request.format.json?
  # @return [nil]                         If no URL was present.
  #
  def make_eds_link(
    label:      nil,
    url:        nil,
    icon:       nil,
    raw:        nil,
    guest:      nil,
    type:       nil,
    separator:  nil,
    opt:        {}
  )
    return unless url.present?
    opt   = opt.except(:type, :expires)
    raw ||= rendering_non_html?(opt)
    guest = %w(true yes on).include?(guest.downcase) if guest.is_a?(String)
    guest = eds_guest?                               if guest.nil?

    if raw
      label ||= EDS_LINK_LABEL
    elsif icon.to_s.start_with?('http')
      label = image_tag(icon)
    else
      label ||= I18n.t('ebsco_eds.links.default')
    end

    url = ((type == 'html') ? ('#' + FULL_TEXT_ANCHOR) : '') if url == 'detail'
    url = request.path + url if url.start_with?('#')

    if raw && url.present?
      url
    elsif raw && guest
      label + I18n.t('ebsco_eds.links.sign_on')
    elsif raw
      label
    elsif url.start_with?('http') && !url.start_with?(root_url)
      outlink(label, url, opt)
    elsif guest
      label += I18n.t('ebsco_eds.links.sign_on')
      link_to(label, signon_redirect(url), opt)
    else
      link_to(label, url, opt)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Return either #EBSCO_NO_LINK or *nil*.
  #
  # @param [Symbol] method
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                         If directed by #RETURN_NIL
  #
  # @see self#EBSCO_NO_LINK
  # @see self#RETURN_NIL
  #
  def return_empty(method)
    EBSCO_NO_LINK unless RETURN_NIL[method]
  end

  # Wrap *s* in an element to make it a subsection heading for an abstract.
  #
  # @param [String] s
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def abstract_subsection(s)
    content_tag(:div, s.to_s.html_safe, class: 'subheading')
  end

end

__loading_end(__FILE__)
