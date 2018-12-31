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

  # URL sign-on path.
  #
  # @type [String]
  #
  SIGN_ON_PATH = '/account/login'

  # Displayed only if a method is set up to avoid returning *nil*.
  #
  # @type [ActiveSupport::SafeBuffer]
  #
  EBSCO_NO_LINK = I18n.t('blacklight.no_link').html_safe.freeze

  # Indicate whether a method should return *nil* if there was no data.
  # If *false* then self#EBSCO_NO_LINK is returned.
  #
  # @type [Hash{Symbol=>Boolean}]
  #
  RETURN_NIL = {
    best_fulltext:              false,
    eds_links:                  false,
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

  # eds_publication_type_label
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  # @see CatalogHelper#format_facet_label
  #
  def eds_publication_type_label(options = nil)
    return raw_value(options) unless request.format.html?
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "&nbsp;\n"
    result =
      Array.wrap(values).map { |v|
        content_tag(:span, v, class: 'label label-default') if v.present?
      }.compact.join(separator).html_safe.presence
    result || (EBSCO_NO_LINK unless RETURN_NIL[__method__])
  end

  # eds_index_publication_info
  #
  # The `options[:value]` will be :eds_composed_title but if it's blank, show
  # the :eds_publication_date instead.
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # TODO: This never gets triggered if :eds_composed_title is missing...
  # Maybe dealing with fields in this way needs to be handled through
  # IndexPresenter.
  #
  def eds_index_publication_info(options = nil)
    return raw_value(options) unless request.format.html?
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "<br/>\n"
    unless values.present?
      doc = (options[:document] if options.respond_to?(:[]))
      values = (doc[:eds_publication_date] if doc.is_a?(Blacklight::Document))
    end
    Array.wrap(values).join(separator).html_safe.presence
  end

  # eds_abstract
  #
  # @param [Hash] options             Supplied by the presenter.
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  # === Implementation Notes
  # Some items have abstracts with implied sections where the "subheading" is
  # simply a <b> element not otherwise distinguished in the text.  This method
  # makes these cases explicit.
  #
  # === Examples
  #
  # @example With implied sections after <br>
  #   /articles/cmedm__30552144
  #
  # @example With implied sections within <b>
  #   /articles/a9h__133419289
  #
  def eds_abstract(options = nil)
    return raw_value(options) unless request.format.html?
    values, opt = extract_config_value(options)
    separator = opt.delete(:separator) || "<br/>\n"
    result = Array.wrap(values).reject(&:blank?).join(separator)

    # === Make implied sections explicit
    if result.gsub!(%r{<br\s*/?>([^:\s]+:)\s*}) { abstract_subsection($1) }
      # (1) For implied sections that follow a <br>, the first implied section
      # will be at the start of the abstract without a <br>.
      result.sub!(/\A([^:\s]+:)\s*/) { abstract_subsection($1) }
    else
      # (2) Handle implied sections within <b>.
      result.gsub!(/<b>\s*([^:<]*:)\s*<\/b>/) { abstract_subsection($1) }
    end

    result.html_safe.presence
  end

  # best_fulltext
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def best_fulltext(options = nil)
    return raw_value(options) unless request.format.html?
    values, opt = extract_config_value(options)
    values = (values.first.presence if values.is_a?(Hash))
    array_of_hashes = (values['links'].to_a if values.is_a?(Hash))
    result =
      if array_of_hashes.present?
        controller = 'articles' # TODO: generalize
        separator  = opt.delete(:separator)
        guest = eds_guest?
        id    = values['id'].to_s.tr('.', '_')
        BEST_FULLTEXT_TYPES.map { |type|
          hash = array_of_hashes.find { |hash| hash['type'] == type }
          url  = hash && hash['url']
          next unless url.present?
          # Use the new fulltext route and controller to avoid time-bombed PDF
          # links.
          pdf = %w(pdf ebook-pdf).include?(type)
          url = "/#{controller}/#{id}/#{type}/fulltext" if pdf
          # Replace 'URL' label for catalog links.
          label = (type == 'cataloglink') ? 'Catalog Link' : hash['label']
          label = 'Full Text' if label.blank?
          authorized_link(guest, label, url)
        }.compact.join(separator).html_safe.presence
      end
    result || (EBSCO_NO_LINK unless RETURN_NIL[__method__])
  end

  # html_fulltext
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  def html_fulltext(options = nil)
    return raw_value(options) unless request.format.html?
    values, opt = extract_config_value(options)
    content  = render_fulltext(values, opt)
    anchor   = content_tag(:div, '', id: FULL_TEXT_ANCHOR, class: 'anchor')
    scroller = content_tag(:div, content, class: 'scroller')
    anchor + scroller
  end

  # fulltext_link
  #
  # @param [Hash] options
  #
  # @return [ActiveSupport::SafeBuffer, nil]
  #
  def fulltext_link(options = nil)
    return raw_value(options) unless request.format.html?
    doc = options.is_a?(Hash) ? options[:document] : options
    return unless doc.is_a?(Blacklight::Document)
    return unless doc[:eds_html_fulltext_available]
    label = I18n.t('ebsco_eds.links.view', default: 'View')
    url = url_for(
      controller: Blacklight::Lens.key_for_doc(doc),
      action:     :show,
      id:         doc.id,
      anchor:     FULL_TEXT_ANCHOR
    )
    authorized_link(eds_guest?, label, url)
  end

  # ebsco_eds_plink
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>", although,
  # under normal circumstances, there should only be one :eds_plink value.
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def ebsco_eds_plink(options = nil)
    return raw_value(options) unless request.format.html?
    values, _ = extract_config_value(options)
    url = Array.wrap(values).first
    outlink(EDS_PLINK_LABEL, url) if url.present?
  end

  # eds_links
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>".
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  #
  # @option options [String] :value
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def eds_links(options = nil)
    all_eds_links(options, EBSCO_LINK_TARGETS)
  end

  # all_eds_links
  #
  # Multiple links are wrapped in "<ul class='list-unstyled'></ul>".
  #
  # @param [String, Array<String>, Hash] options  Link value(s).
  # @param [Array]  types                         Default: all types.
  # @param [String] separator                     Default: "\n".
  #
  # @option options [String] :value
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                                 If no URLs were present.
  #
  def all_eds_links(options = nil, types = nil, separator = "\n")
    return raw_value(options) unless request.format.html?
    values =
      case options
        when Hash  then options[:value]
        when Array then options.map { |value| { url: value } }
        else            { url: options.to_s }
      end
    types = types.presence
    links =
      Array.wrap(values).map { |hash|
        next if hash.blank? || (types && !types.include?(hash['type']))
        make_eds_link(hash)
      }.compact
    if links.blank?
      EBSCO_NO_LINK unless RETURN_NIL[__method__]
    elsif links.size == 1
      links.first
    else
      content_tag(:ul, links.join(separator).html_safe, class: 'list-unstyled')
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

  # authorized_link
  #
  # @param [TrueClass, FalseClass, String] guest
  # @param [String]                        label
  # @param [String]                        url
  # @param [Hash, nil]                     opt
  #
  # @return [String, nil]
  #
  def authorized_link(guest, label, url, opt = nil)
    return unless url.present?
    guest   = %w(true yes on).include?(guest.downcase) if guest.is_a?(String)
    guest   = eds_guest?                               if guest.nil?
    label ||= I18n.t('ebsco_eds.links.default')
    opt   ||= {}
    anchor  = url.start_with?('#')
    direct  = anchor || !url.start_with?('http') || url.start_with?(root_url)
    if guest
      label += I18n.t('ebsco_eds.links.sign_on')
      url = request.path + url if anchor
      url = "?redirect=#{u(url)}"
      url = "#{SIGN_ON_PATH}#{url}"
      link_to(label, url, opt)
    elsif direct
      link_to(label, url, opt)
    else
      outlink(label, url, opt)
    end
  end

  # make_eds_link
  #
  # @param [Array] *args
  #
  # @option args.last [String]  'label'
  # @option args.last [String]  'url'
  # @option args.last [String]  'icon'
  # @option args.last [String]  'type'      Ignored.
  # @option args.last [String]  'expires'   Ignored.
  # @option args.last [Boolean] :guest
  #
  # @return [ActiveSupport::SafeBuffer]
  # @return [nil]                           If no URL was provided.
  #
  def make_eds_link(*args)

    # Take values from options if present.
    opt   = args.extract_options!.except('type', 'expires')
    label = opt.delete('label').presence
    url   = opt.delete('url').presence
    icon  = opt.delete('icon').presence
    guest = opt.delete('guest')
    guest = opt.delete(:guest) || guest
    opt.delete('type')
    opt.delete('expires')

    # Values from the argument list are given preference.
    label = args.shift || label
    url   = args.shift || url
    icon  = args.shift || icon

    # Show the link, routing through the sign-on if necessary.
    return unless url.present?
    label = image_tag(icon) if icon.to_s.match(/^http/)
    label ||= EDS_LINK_LABEL
    url = '#' + FULL_TEXT_ANCHOR if url == 'detail'
    authorized_link(guest, label, url, opt)

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  def abstract_subsection(s)
    content_tag(:div, s.to_s.html_safe, class: 'subheading')
  end

end

__loading_end(__FILE__)
