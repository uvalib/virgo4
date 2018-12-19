# lib/ext/ebsco-eds/lib/ebsco/eds/record.rb
#
# Inject EBSCO::EDS::Record extensions and replacement methods.

__loading_begin(__FILE__)

# Override EBSCO::EDS definitions.
#
# @see EBSCO::EDS::Record
#
module EBSCO::EDS::RecordExt

  require 'i18n'

  # The RELAXED config:
  # @see https://github.com/rgrove/sanitize/blob/master/lib/sanitize/config/relaxed.rb
  #
  # @type [Hash{Symbol=>Array<String>}]
  #
  SANITIZE_BASE_CONFIG = Sanitize::Config::RELAXED

  # Additional HTML elements that are not removed during sanitization.
  #
  # @type [Array<String>]
  #
  SANITIZE_PERMITTED_ELEMENTS = (
    SANITIZE_BASE_CONFIG[:elements] + %w(relatesto searchlink)
  ).deep_freeze

  # Additional HTML attributes that are not removed during sanitization.
  #
  # @type [Array<String>]
  #
  SANITIZE_PERMITTED_ATTRIBUTES =
    SANITIZE_BASE_CONFIG[:attributes]
      .merge('searchlink' => %w(fieldcode term))
      .deep_freeze

  # General sanitization configuration.
  # @see self#html_decode_and_sanitize
  #
  # @type [Hash{Symbol=>Array<String>}]
  #
  SANITIZE_CONFIG =
    Sanitize::Config.merge(
      SANITIZE_BASE_CONFIG,
      elements:   SANITIZE_PERMITTED_ELEMENTS,
      attributes: SANITIZE_PERMITTED_ATTRIBUTES
    ).deep_freeze

  # Default replacements of XML node names with related HTML element names.
  #
  # @type [HashWithIndifferentAccess{String=>String}]
  #
  FULL_TEXT_DEFAULT_TRANSFORM = {
    title:    'h1',
    sbt:      'h2',
    jsection: 'h3',
    et:       'h3',
  }.with_indifferent_access.deep_freeze

  # Replace received XML node names with related HTML element names from
  # 'ebsco_eds.html_fulltext' or #FULL_TEXT_DEFAULT_TRANSFORM.
  # @see config/locale/ebsco_eds.yml
  #
  # @type [Proc]
  #
  SANITIZE_TRANSFORMER =
    lambda do |env|
      node = env[:node]
      html_element =
        I18n.t(
          "ebsco_eds.html_fulltext.#{node.name}",
          default: FULL_TEXT_DEFAULT_TRANSFORM[node.name]
        )
      node.name = html_element if html_element
    end

  # Sanitization configuration for full-text content.
  # @see self#html_fulltext
  #
  # @type [Hash{Symbol=>Object}]
  #
  SANITIZE_FULLTEXT_CONFIG =
    SANITIZE_CONFIG.merge(
      remove_contents: true,
      transformers:    [SANITIZE_TRANSFORMER]
    ).deep_freeze

  # Date parts and widths (in characters).
  #
  # @see config/locales/ebsco_eds.yml
  # @see self#bib_publication_date
  #
  # @type [Hash{Symbol=>Numeric}]
  #
  PUB_DATE_WIDTH = {
    Y: I18n.t('ebsco_eds.bib_publication_date.width.year',  default: 4),
    M: I18n.t('ebsco_eds.bib_publication_date.width.month', default: 2),
    D: I18n.t('ebsco_eds.bib_publication_date.width.day',   default: 2)
  }.deep_freeze

  # ===========================================================================
  # :section: MISC HELPERS
  # ===========================================================================

  public

  # The title.
  #
  # @param [String, nil] fallback     Displayed for items without a title.
  #
  # @return [String]                  Fallback: 'ebsco_eds.message.title'
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#title
  #
  # The default fallback title is taken from 'ebsco_eds.message.title':
  # @see config/locales/ebsco_eds.yml
  #
  def title(fallback = nil)
    bib_title || get_item_data(name: 'Title') || fallback ||
      I18n.t('ebsco_eds.message.title', default: 'Please login to view')
  end

  # The source title (e.g.: 'Salem Press Encyclopedia')
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#source_title
  #
  def source_title
    result = bib_source_title || get_item_data(name: 'TitleSource')
    result unless result == title # Suppress if it's identical to title.
  end

  # The full text of the item embedded in the record.
  #
  # @param [Sanitize::Config, nil] sanitize_config  If @decode_sanitize_html is
  #                                                 *true* (Default:
  #                                                 #SANITIZE_FULLTEXT_CONFIG)
  #
  # @return [String, nil]
  #
  # @see self#SANITIZE_FULLTEXT_CONFIG
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#html_fulltext
  #
  def html_fulltext(sanitize_config = nil)
    return unless html_fulltext_available
    value = @record.dig('FullText', 'Text', 'Value')
    if @decode_sanitize_html && false # TODO: This requires special handling...
      sanitize_config ||= SANITIZE_FULLTEXT_CONFIG
      value = html_decode_and_sanitize(value, sanitize_config)
    end
    value
  end

  # ===========================================================================
  # :section: LINK HELPERS
  # ===========================================================================

  public

  # All available fulltext links.
  #
  # @return [Array<Hash>]
  #
  # Default link labels and icons in 'ebsco_eds.fulltext_links':
  # @see config/locales/ebsco_eds.yml
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#fulltext_links
  #
  def fulltext_links

    result = []

    items        = Array.wrap(@record['Items'])
    ebsco_links  = Array.wrap(@record.dig('FullText', 'Links'))
    custom_links = Array.wrap(@record.dig('FullText', 'CustomLinks'))

    result +=
      ebsco_links.map do |link|
        next unless link['Type'] == 'pdflink'
        @eds_pdf_fulltext_available = true
        make_link(__method__, 'pdf', true, link['Url'])
      end

    result +=
      ebsco_links.map do |link|
        next unless link['Type'] == (type = 'ebook-pdf')
        @eds_ebook_pdf_fulltext_available = true
        make_link(__method__, type, true, link['Url'])
      end

    result +=
      ebsco_links.map do |link|
        next unless link['Type'] == (type = 'ebook-epub')
        @eds_ebook_epub_fulltext_available = true
        make_link(__method__, type, true, link['Url'])
      end

    result +=
      items.map do |item|
        next unless item['Group'] == 'URL'
        data      = item['Data']
        label     = item['Label']
        link_term = 'linkTerm=&quot;'
        if data.include?(link_term)
          url_start = data.index(link_term) + 15
          link_url  = data[url_start..-1]
          url_end   = link_url.index('&quot;') - 1
          link_url  = link_url[0..url_end]
          unless (link_label = label)
            label_start = data.index('link&gt;') + 8
            link_label  = data[label_start..-1].strip
          end
        else
          link_url   = data
          link_label = label
        end
        make_link(__method__, 'cataloglink', false, link_url, link_label)
      end

    result +=
      ebsco_links.map do |link|
        next unless link['Type'] == 'other'
        @eds_pdf_fulltext_available = true
        make_link(__method__, 'smartlinks', false, link['Url'])
      end

    result +=
      custom_links.map do |link|
        make_link(__method__, 'customlink-fulltext', false, link)
      end

    result << make_link(__method__, 'html', false) if html_fulltext_available

    result.compact

  end

  # All available non-fulltext links.
  #
  # @return [Array<Hash>]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#non_fulltext_links
  #
  def non_fulltext_links
    Array.wrap(@record['CustomLinks']).map { |link|
      make_link(__method__, 'customlink-other', false, link)
    }.compact
  end

  # ===========================================================================
  # :section: LINK HELPERS
  # ===========================================================================

  protected

  # make_link
  #
  # @param [Array] args
  #   arg[0]  I18n scope  [Symbol, String]
  #   arg[1]  Type        [String]
  #   arg[2]  Expires     [Boolean]
  #   arg[3]  URL         [String, Array<String,String,String>, Hash]
  #   arg[4]  Label       (if URL is a String)
  #   arg[5]  Icon        (if URL is a String)
  #
  # @return [Hash]
  #
  def make_link(*args)
    i18n_scope, type, expires, lnk, label, icon = args
    i18n_scope =
      ['ebsco_eds', i18n_scope, type].map { |v|
        v.to_s.underscore if v.present?
      }.compact.join('.')
    case lnk
      when Hash  then url, label, icon = lnk['Url'], lnk['Text'], lnk['Icon']
      when Array then url, label, icon = lnk
      else            url = lnk
    end
    url     &&= add_protocol(url) if type.start_with?('customlink-')
    url     ||= 'detail'
    label   ||= I18n.t("#{i18n_scope}.label", default: url)
    icon    ||= I18n.t("#{i18n_scope}.icon")
    expires ||= false
    { url: url, label: label, icon: icon, type: type, expires: expires }
  end

  # ===========================================================================
  # :section: BIB - IS PART OF (journal, book)
  # ===========================================================================

  public

  # bib_issn_print
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_issn_print
  #
  def bib_issn_print
    get_bib_identifier_values('issn-print').first
  end

  # bib_issn_electronic
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_issn_electronic
  #
  def bib_issn_electronic
    get_bib_identifier_values('issn-electronic').first
  end

  # bib_issns
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_issns
  #
  def bib_issns
    get_bib_identifier_values('issn', except: 'locals')
  end

  # bib_isbn_print
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_isbn_print
  #
  def bib_isbn_print
    get_bib_identifier_values('isbn-print').first
  end

  # bib_isbn_electronic
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_isbn_electronic
  #
  def bib_isbn_electronic
    get_bib_identifier_values('isbn-electronic').first
  end

  # bib_issns
  #
  # @return [Array<String>]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_isbns
  #
  def bib_isbns
    get_bib_identifier_values('isbn', except: 'locals')
  end

  # ===========================================================================
  # :section: BIB - IS PART OF (journal, book)
  # ===========================================================================

  protected

  # get_bib_identifier_values
  #
  # @param [String]    only           E.g.: 'isbn', 'issn'
  # @param [Hash, nil] opt
  #
  # @option opt [String] :except
  #
  # @return [Array<String>]
  #
  def get_bib_identifier_values(only, opt = nil)
    only   = only&.to_s
    except = (opt[:except].presence if opt.is_a?(Hash))
    get_bib_identifiers.map { |id|
      type = id['Type'].to_s
      next if only   && !only.include?(type)
      next if except && type.include?(except)
      id['Value']
    }.compact
  end

  # get_bib_identifiers
  #
  # @return [Array<Hash>]
  #
  def get_bib_identifiers
    @bib_identifiers ||= Array.wrap(@bib_part&.dig('BibEntity', 'Identifiers'))
  end

  # ===========================================================================
  # :section: BIB - IS PART OF (journal, book)
  # ===========================================================================

  public

  # bib_publication_date
  #
  # @return [String, nil]
  #
  # @see self#PUB_DATE_WIDTH
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_publication_date
  #
  def bib_publication_date
    date   = get_bib_pub_date
    values = []
    format =
      PUB_DATE_WIDTH.map { |part, digits|
        v = date[part.to_s].to_i
        v = nil unless v > 0
        values << v if v
        v ? "%0#{digits}d" : ('?' * digits)
      }.join('-')
    format % values
  end

  # bib_publication_year
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_publication_year
  #
  def bib_publication_year
    get_bib_pub_date['Y'].presence
  end

  # bib_publication_month
  #
  # @return [String, nil]
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#bib_publication_month
  #
  def bib_publication_month
    get_bib_pub_date['M'].presence
  end

  # ===========================================================================
  # :section: BIB - IS PART OF (journal, book)
  # ===========================================================================

  protected

  # get_bib_pub_date
  #
  # @return [Hash]                    Empty if no dates were found.
  #
  def get_bib_pub_date
    @bib_pub_date ||=
      begin
        dates = @bib_part&.dig('BibEntity', 'Dates')&.presence
        dates&.find { |item| item['Type'] == 'published' } || {}
      end
  end

  # ===========================================================================
  # :section: ITEM DATA HELPERS
  # ===========================================================================

  public

  # Decode any HTML elements and then run it through sanitize to preserve
  # entities (e.g.: ampersand) and strip out elements/attributes that aren't
  # explicitly whitelisted.
  #
  # @param [String]                data
  # @param [Sanitize::Config, nil] sanitize_config  Default: #SANITIZE_CONFIG
  #
  # @return [String]
  #
  # @see self#SANITIZE_CONFIG
  #
  # This method overrides:
  # @see EBSCO::EDS::Record#html_decode_and_sanitize
  #
  def html_decode_and_sanitize(data, sanitize_config = nil)
    data = CGI.unescapeHTML(data.to_s)
    # Need to double-unescape data with an ephtml section.
    if data =~ /<ephtml>/
      data = CGI.unescapeHTML(data).gsub(/\\"/, '"').gsub(/\\n /, '')
    end
    sanitize_config ||= SANITIZE_CONFIG
    Sanitize.fragment(data, sanitize_config)
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override EBSCO::EDS::Record => EBSCO::EDS::RecordExt

__loading_end(__FILE__)
