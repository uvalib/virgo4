# app/models/concerns/blacklight/eds/document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require_relative '../lens/document'
require_relative 'document/export'
require_relative 'document/schema_org'

# Blacklight::Eds::Document
#
# == Implementation Notes
# Blacklight::Document::ActiveModelShim#to_partial_path is not overridden here
# because the partial 'articles/document' is not currently defined -- all
# document types are using 'app/views/catalog/_document.html.erb'.
#
# @see Blacklight::Lens::Document
#
module Blacklight::Eds::Document

  extend ActiveSupport::Concern

  include Blacklight::Lens::Document
  include Blacklight::Eds::Document::Export
  include Blacklight::Eds::Document::SchemaOrg
  extend  Blacklight::Eds::Document::SchemaOrg

  include HtmlHelper

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Document::Email      unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::Sms        unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::DublinCore unless ONLY_FOR_DOCUMENTATION

  # ===========================================================================
  # :section: Blacklight::Document::ActiveModelShim overrides
  # ===========================================================================

  public

  # Unique ID for the document.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ActiveModelShim#id
  #
  def id
    super.to_s.tr('.', '_')
  end

  # ===========================================================================
  # :section: Blacklight::Lens::Document overrides
  # ===========================================================================

  public

  # Indicate the originating lens.
  #
  # @return [Symbol]
  #
  # This method overrides:
  # @see Blacklight::Lens::Document#lens
  #
  def lens
    @lens || :articles
  end

  # The document ID to be used for external references
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Lens::Document#export_id
  #
  def export_id
    "#{self[:eds_database_id]}:#{self[:eds_accession_number]}"
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Metadata fields that trigger #modify_dbid processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_ID_KEYS = %i(id).freeze

  # Metadata fields that trigger #doi_link processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_DOI_KEYS = %i(eds_document_doi).freeze

  # Metadata fields that trigger #mesh_link processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_MESH_KEYS = %i(eds_subjects_mesh).freeze

  # Metadata fields that trigger #naics_link processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_NAICS_KEYS = %i(eds_code_naics).freeze

  # Metadata fields that trigger #relates_to processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_RELATE_KEYS = %i(
    eds_author_affiliations
    eds_authors_composed
  ).freeze

  # Metadata fields that trigger #search_link processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_SEARCH_KEYS = %i(
    eds_subjects
    eds_subjects_company
    eds_subjects_genre
    eds_subjects_geographic
    eds_subjects_person
  ).freeze

  # Metadata fields that trigger #mailto_link processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_EMAIL_KEYS = %i(
    eds_authors_composed
    eds_subjects
    eds_subjects_company
    eds_subjects_genre
    eds_subjects_geographic
    eds_subjects_person
  )

  # Metadata fields that trigger #sanitize processing.
  #
  # @type [Array<Symbol>]
  #
  # @see self#prepare
  #
  EDS_HTML_KEYS = (
    EDS_MESH_KEYS +
    EDS_NAICS_KEYS +
    EDS_RELATE_KEYS +
    EDS_SEARCH_KEYS +
    EDS_EMAIL_KEYS + %i(
      eds_abstract
      eds_abstract_supplied_copyright
      eds_author_supplied_keywords
      eds_composed_title
      eds_descriptors
      eds_document_type
      eds_subjects_bisac
      eds_subset
    )
  ).uniq.freeze

  # Match an HTML break as "<br>" and/or "<br/>" and/or "<br></br>".
  #
  # @type [Regexp]
  #
  # @see self#prepare
  #
  BREAK_REGEX = %r{<br>(\s*</br>)?|<br/>}i

  # Rails treats the substring in the path after a dot as the requested MIME
  # type for output, so dots in EBSCO item IDs must translated to something
  # else.
  #
  # @type [String]
  #
  # @see self#modify_dbid
  #
  EDS_ID_DOT_REPLACEMENT = '_'

  # Sanity check.
  Rails.error {
    "ID_DOT_REPLACEMENT: #{EDS_ID_DOT_REPLACEMENT.inspect}: must be one char"
  } unless EDS_ID_DOT_REPLACEMENT.size == 1

  # Used to turn terms into search links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#relates_to
  #
  RELATES_TO_REGEX = %r{
    (\s*;?\s*)                        # Semicolon (instead of break)       ($1)
    (\s*\[?\s*)                       # Optional outer left bracket        ($2)
    (<(relatesTo)\s*([^>]*)\s*>)      # Start tag and attributes     ($3,$4,$5)
      \s*\[?\s*                       # Optional inner left bracket
      ([^\[\]<]+)                     # Reference number                   ($6)
      \s*\]?\s*                       # Optional inner right bracket
    (</\s*\4\s*>)                     # Close tag                          ($7)
    (\s*\]?\s*)                       # Optional outer right bracket       ($8)
  }ix

  # Used to turn terms into search links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#search_link
  #
  SEARCH_LINK_REGEX = %r{
    (<(searchLink)\s*([^>]*)\s*>)     # Start tag and attributes     ($1,$2,$3)
      \s*([^<]+)\s*                   # Link text                          ($4)
    (</\s*\2\s*>)                     # Close tag                          ($5)
  }ix

  # Used to turn MeSH terms into external links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#mesh_link
  #
  MESH_REGEX = SEARCH_LINK_REGEX

  # URL template for MeSH terms.
  #
  # @type [String]
  #
  # @see self#mesh_link
  #
  MESH_LINK = 'https://www.ncbi.nlm.nih.gov/mesh?term=%s'

  # Used to turn NAICS terms into external links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#naics_link
  #
  NAICS_REGEX = SEARCH_LINK_REGEX

  # URL template for NAICS codes.
  #
  # @type [String]
  #
  # @see self#naics_link
  #
  NAICS_LINK =
    'https://www.census.gov/cgi-bin/sssd/naics/naicsrch?input=%s&search=2017'

  # Adjust certain EBSCO field values before passing the data to the base
  # initializer.
  #
  # @param [Hash]    data
  # @param [Boolean] preserve_blanks  If *true*, don't discard blank fields.
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  #
  # @see self#sanitize
  # @see self#modify_dbid
  # @see self#relates_to
  # @see self#doi_link
  # @see self#search_link
  # @see self#mesh_link
  # @see self#naics_link
  # @see self#mailto_link
  #
  def prepare(data, preserve_blanks = nil)
    data ||= {}
    @raw_source = data.sort_by { |k, _| k.to_s }.to_h
    data.map { |k, v|

      # Determine the nature of the metadata field value.
      k = k.to_sym
      string = v.is_a?(String)
      array  = v.is_a?(Array)
      hash   = v.is_a?(Hash)
      scalar =
        if v.blank?
          v.is_a?(FalseClass)
        elsif array
          v.none? { |e| e.is_a?(String) || e.is_a?(Array) || e.is_a?(Hash) }
        else
          !string && !hash
        end

      # Allow single or multiple scalars through without any processing.
      unless scalar || v.blank?

        # Split strings with "<br/>" into arrays of strings.
        v = Array.wrap(v)
        if string || v.first.is_a?(String)
          v = v.join('<br/>').gsub(BREAK_REGEX, '<br/>')
          v = v.split('<br/>').map(&:strip).reject(&:blank?)
          v = v.first if string && (v.size == 1)
        end

        # Determine whether this is a metadata field that should be processed.
        process = v.presence && {
          html:   EDS_HTML_KEYS.include?(k),
          id:     EDS_ID_KEYS.include?(k),
          relate: EDS_RELATE_KEYS.include?(k),
          doi:    EDS_DOI_KEYS.include?(k),
          search: EDS_SEARCH_KEYS.include?(k),
          mesh:   EDS_MESH_KEYS.include?(k),
          naics:  EDS_NAICS_KEYS.include?(k),
          email:  EDS_EMAIL_KEYS.include?(k)
        }

        # Process each string element of *v* based on the nature of *k*.
        if process&.values&.any?
          v = apply(v) do |s|
            s = sanitize(s, process[:html])
            s = modify_dbid(s) if process[:id]
            s = relates_to(s)  if process[:relate]
            s = doi_link(s)    if process[:doi]
            s = search_link(s) if process[:search]
            s = mesh_link(s)   if process[:mesh]
            s = naics_link(s)  if process[:naics]
            s = mailto_link(s) if process[:email]
            s = s.strip        if s.is_a?(String)
            s = s.html_safe    if process[:html]
            s
          end
        end
      end

      # Skip blank strings, arrays or hashes unless preserving blanks.
      unless v.present? || v.is_a?(FalseClass)
        next unless preserve_blanks
        v = string ? '' : array ? [] : hash ? {} : nil
      end

      # Emit the metadata field and its value.
      [k, v]
    }.compact.to_h.with_indifferent_access
  end

  # Apply the block to every non-Enumerable in *item*.
  #
  # @param [Object] item
  #
  # @return [Object]
  #
  def apply(item, &block)
    case item
      when Hash   then item.map { |k, v| [k, apply(v, &block)] }.to_h
      when Array  then item.map { |v| apply(v, &block) }
      when String then yield(item)
      else             item
    end
  end

  # Selectively remove HTML from *s*.
  #
  # @param [String]  s
  # @param [Boolean] allow_html       Selectively allow some HTML constructs.
  #
  # @return [String]
  #
  def sanitize(s, allow_html = nil)
    # Correct over-quoting seen on EBSCO <searchLink> elements.
    s = s.gsub(/%22"|"%22/, %q("))
    if allow_html
      s # TODO: partial sanitize
    else
      s # TODO: full sanitize
    end
  end

  # Adjust EDS item identifiers so that they can be used with Rails paths.
  #
  # E.g., "/articles/db__idbase.part2" would appear to Rails as ID "db__idbase"
  # with format "part2" -- translating the dots prevents Rails from
  # interpreting it this way.)
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#EDS_ID_DOT_REPLACEMENT
  #
  def modify_dbid(s)
    s.tr('.', EDS_ID_DOT_REPLACEMENT)
  end

  # Replace email addresses with "mailto:" links.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see HtmlHelper#email_link
  #
  # == Examples
  #
  # @example With mailing addresses in :eds_authors_composed
  #   /articles/ehh__119126750
  #
  def mailto_link(s)
    s.include?('@') ? s.gsub(email_regex) { |x| email_link(x) } : s
  end

  # Create a DOI URL for each matching portion of *s*.
  #
  # Normalize DOIs as the canonical URL path (regardless of how the publisher
  # supplied the DOI value).
  #
  # @param [String] s
  #
  # @return [String]
  #
  def doi_link(s)
    URI.parse(URI.escape(s)).tap { |uri|
      uri.scheme = 'https'
      uri.host   = 'doi.org'
      uri.path   = '/' + uri.path unless uri.path.start_with?('/')
    }.to_s
  end

  # Ensure that <relatesTo> elements are enclosed in square brackets.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#RELATES_TO_REGEX
  # @see HtmlHelper#path_link
  #
  # == Implementation Notes
  # Using CSS to add separation between <relatesTo> and its neighboring content
  # works visually, but this does not convey if the results are HTML-sanitized
  # (e.g. when copying to the clipboard).  Instead, this method ensures that
  # actual spaces are present on either side of the element.
  #
  # == Examples
  #
  # @example Multiple authors with one affiliation
  #   /articles/a9h__129618192
  #   /articles/a9h__133381278
  #
  # @example Multiple authors with multiple affiliations
  #   /articles/a9h__133686484
  #   /articles/a9h__133436856
  #
  # @example Authors with more than one affiliation
  #   /articles/a9h__133686482
  #   /articles/a9h__133436861
  #   /articles/a9h__133436852
  #
  def relates_to(s)
    s.gsub(RELATES_TO_REGEX) do
      list_join, lsb, open_tag, number, close_tag, rsb = $1, $2, $3, $6, $7, $8
      list_join = '<br/>' if list_join&.include?(';')
      lsb = ' ' if lsb.blank? || (lsb = lsb.tr('[', '')).empty?
      rsb = ' ' if rsb.blank? || (rsb = rsb.tr(']', '')).empty?
      [list_join, lsb, open_tag, '[', number, ']', close_tag, rsb].join
    end
  end

  # Create a search URL link for each matching portion of *s*.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#SEARCH_LINK_REGEX
  # @see HtmlHelper#path_link
  #
  # == Examples
  #
  # @example Multiple search links
  #   /articles/a9h__133661705
  #
  def search_link(s)
    s.gsub(SEARCH_LINK_REGEX) do
      open_tag, attr, label, close_tag = $1, $3, $4, $5
      opt  = attr_to_options(attr)
      term = opt[:term] || CGI.unescapeHTML(label)
      code = opt[:fieldcode] || opt[:fieldCode]
      search =
        case code
          when 'TI' then 'title'
          when 'AU' then 'author'
          when 'SU' then 'subject'
        end
      path_opt = {
        controller:   :articles, # TODO
        search_field: search,
        q:            %Q("#{term}"),
      }.compact
      link = path_link(label.html_safe, path_opt)
      [open_tag, link, close_tag].join
    end
  end

  # Create a MeSH URL link for each matching portion of *s*.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#MESH_REGEX
  # @see self#MESH_LINK
  # @see HtmlHelper#outlink
  #
  # == Examples
  #
  # @example MeSH terms from element label
  #   /articles/cmedm__27875992
  #
  def mesh_link(s)
    s.gsub(MESH_REGEX) do
      open_tag, attr, label, close_tag = $1, $3, $4, $5
      opt  = attr_to_options(attr)
      term = opt[:term] || CGI.unescapeHTML(label)
      url  = MESH_LINK % term
      link = outlink(label.html_safe, url)
      [open_tag, link, close_tag].join
    end
  end

  # Create a NAICS URL link for each matching portion of *s*.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#NAICS_REGEX
  # @see self#NAICS_LINK
  # @see HtmlHelper#outlink
  #
  # == Examples
  #
  # @example Valid and invalid NAICS codes
  #   /articles/a9h__133661705
  #
  def naics_link(s)
    s.gsub(NAICS_REGEX) do
      open_tag, code, close_tag = $1, $4, $5
      url  = NAICS_LINK % code
      link = outlink(code, url)
      [open_tag, link, close_tag].join
    end
  end

end

__loading_end(__FILE__)
