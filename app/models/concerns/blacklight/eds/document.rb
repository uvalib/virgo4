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

  EDS_ID_KEYS     ||= %i(id).freeze
  EDS_DOI_KEYS    ||= %i(eds_document_doi).freeze
  EDS_MESH_KEYS   ||= %i(eds_subjects_mesh).freeze
  EDS_NAICS_KEYS  ||= %i(eds_code_naics).freeze

  EDS_SEARCH_KEYS ||= %i(
    eds_subjects
    eds_subjects_company
    eds_subjects_genre
    eds_subjects_geographic
    eds_subjects_person
  ).freeze

  EDS_EMAIL_KEYS ||= %i(
    eds_authors_composed
    eds_subjects
    eds_subjects_company
    eds_subjects_geographic
    eds_subjects_genre
    eds_subjects_person
  )

  EDS_COMPOSED_KEYS ||= %i(
    eds_abstract
    eds_abstract_supplied_copyright
    eds_author_affiliations
    eds_author_supplied_keywords
    eds_composed_title
    eds_descriptors
    eds_document_type
    eds_subjects_bisac
    eds_subset
  ).freeze

  EDS_HTML_KEYS ||= (
    EDS_MESH_KEYS +
    EDS_NAICS_KEYS +
    EDS_SEARCH_KEYS +
    EDS_EMAIL_KEYS +
    EDS_COMPOSED_KEYS
  ).uniq.freeze

  # Used to turn MeSH terms into external links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#mesh_link
  #
  MESH_REGEX = %r{                    # gsub match
    (<searchLink[^>]* term=")         # $1
    ([^"]*)                           # $2 - search term
    ("[^>]*>)                         # $3
    ([^<]+)                           # $4 - link text
    (</searchLink>)                   # $5
  }x

  # URL template for MeSH terms.
  #
  # @type [String]
  #
  # @see self#mesh_link
  #
  MESH_LINK = 'https://www.ncbi.nlm.nih.gov/mesh/?term=%s'

  # Used to turn NAICS terms into external links via #gsub.
  #
  #   $1 - search term and link text
  #
  # @type [Regexp]
  #
  # @see self#naics_link
  #
  NAICS_REGEX = %r{                   # gsub match
    (\d+)                             # $1 - search term and link text
    (</searchLink>)                   # $2
  }x

  # URL template for NAICS codes.
  #
  # @type [String]
  #
  # @see self#naics_link
  #
  NAICS_LINK =
    'https://www.census.gov/cgi-bin/sssd/naics/naicsrch?input=%s&search=2017'

  # Used to turn terms into search links via #gsub.
  #
  # @type [Regexp]
  #
  # @see self#search_link
  #
  SEARCH_REGEX = %r{                  # gsub match
    (<searchLink[^>]* fieldcode=")    # $1
    ([^"]*)                           # $2 - field code ('SU', 'DE', etc.)
    ("[^>]* term=")                   # $3
    ([^"]*)                           # $4 - search term
    ("[^>]*>)                         # $5
    ([^<]+)                           # $6 - link text
    (</searchLink>)                   # $7
  }x

  # Adjust certain EBSCO field values before passing the data to the base
  # initializer.
  #
  # @param [Hash]    data
  # @param [Boolean] preserve_blanks  If *true*, don't discard blank fields.
  #
  # @return [ActiveSupport::HashWithIndifferentAccess]
  #
  # @see self#EDS_ID_KEYS
  # @see self#EDS_DOI_KEYS
  # @see self#EDS_HTML_KEYS
  # @see self#mesh_link
  # @see self#naics_link
  #
  def prepare(data, preserve_blanks = nil)
    @raw_source = data
    (data || {}).map { |k, v|
      next unless preserve_blanks || v.is_a?(FalseClass) || v.present?
      k = k.to_sym

      # Split strings with "<br>" into arrays of strings.
      v = v.first if v.is_a?(Array) && (v.size == 1)
      v = v.split('<br>') if v.is_a?(String) && v.include?('<br>')

      # Process each string element of *v* based on the nature of *k*.
      process = {
        doi:    EDS_DOI_KEYS.include?(k),
        email:  EDS_EMAIL_KEYS.include?(k),
        html:   EDS_HTML_KEYS.include?(k),
        id:     EDS_ID_KEYS.include?(k),
        mesh:   EDS_MESH_KEYS.include?(k),
        naics:  EDS_NAICS_KEYS.include?(k),
        search: EDS_SEARCH_KEYS.include?(k),
      }
      v = apply(v) do |s|
        s = sanitize(s, process[:html])
        s = modify_dbid(s) if process[:id]
        s = doi_link(s)    if process[:doi]
        s = search_link(s) if process[:search]
        s = mesh_link(s)   if process[:mesh]
        s = naics_link(s)  if process[:naics]
        s = mailto_link(s) if process[:email]
        process[:html] ? s.html_safe : s
      end

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
      when Hash     then item.map { |k, v| [k, apply(v, &block)] }.to_h
      when Array    then item.map { |v| apply(v, &block) }
      when String   then yield(item)
      else               item
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
    s = s.gsub(/%22"|"%22/, %q(")) #if allow_html
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
  # @param [String] replacement       Default: '_'.
  #
  # @return [String]
  #
  def modify_dbid(s, replacement = '_')
    s.tr('.', replacement)
  end

  # Replace email addresses with "mailto:" links.
  #
  # @param [String] s
  #
  # @return [String]
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

  # Create a search URL link for each matching portion of *s*.
  #
  # @param [String] s
  #
  # @return [String]
  #
  # @see self#SEARCH_REGEX
  # @see self#SEARCH_LINK
  #
  def search_link(s)
    s.gsub(SEARCH_REGEX) do
      path_opt = { controller: :articles } # TODO
      search =
        case $2
          when 'TI' then 'title'
          when 'AU' then 'author'
          when 'SU' then 'subject'
        end
      path_opt[:search_field] = search if search.present?
      path_opt[:q] = %Q("#{$4}")
      label = $6.html_safe
      link  = path_link(label, path_opt)
      [$1, $2, $3, $4, $5, link, $7].join
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
  #
  def mesh_link(s)
    s.gsub(MESH_REGEX) do
      label = $4.html_safe
      url   = MESH_LINK % $2
      link  = outlink(label, url)
      [$1, $2, $3, link, $5].join
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
  #
  def naics_link(s)
    s.gsub(NAICS_REGEX) do
      label = $1
      url   = NAICS_LINK % $1
      link  = outlink(label, url)
      [link, $2].join
    end
  end

end

__loading_end(__FILE__)
