# app/models/concerns/blacklight/eds/document_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Blacklight::Eds::DocumentEds
#
# == Implementation Notes
# Blacklight::Document::ActiveModelShim#to_partial_path is not overridden here
# because the partial 'articles/document' is not currently defined -- all
# document types are using 'app/views/catalog/_document.html.erb'.
#
# @see Blacklight::Solr::DocumentExt
# @see Blacklight::Document
#
module Blacklight::Eds::DocumentEds

  extend ActiveSupport::Concern

  include Blacklight::Solr::Document
  include Blacklight::DocumentExt

  # Needed for RubyMine to indicate overrides.
  include Blacklight::Document::Email      unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::Sms        unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Document::DublinCore unless ONLY_FOR_DOCUMENTATION
  include Blacklight::Solr::Document::Marc unless ONLY_FOR_DOCUMENTATION

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
  # :section: Blacklight::Solr::Document::MarcExport replacements
  # ===========================================================================

  public

  # Export in XML format.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_xml
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_xml
  #
  def export_as_xml
    super # TODO: XML export for non-MARC
  end

  # Emit an APA (American Psychological Association) bibliographic citation
  # from the :citation_apa field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_apa_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_apa_citation_txt
  #
  def export_as_apa_citation_txt
    self[:citation_apa]&.html_safe || super # TODO: APA for non-MARC
  end

  # Emit an MLA (Modern Language Association) bibliographic citation from the
  # :citation_mla field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_mla_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_mla_citation_txt
  #
  def export_as_mla_citation_txt
    self[:citation_mla]&.html_safe || super # TODO: MLA for non-MARC
  end

  # Emit an CMOS (Chicago Manual of Style) bibliographic citation from the
  # :citation_chicago field.
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_chicago_citation_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_chicago_citation_txt
  #
  def export_as_chicago_citation_txt
    self[:citation_chicago]&.html_safe || super # TODO: CMOS for non-MARC
  end

  # Exports as an OpenURL KEV (key-encoded value) query string.
  #
  # @param [String] format
  #
  # @return [ActiveSupport::SafeBuffer]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_openurl_ctx_kev
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_openurl_ctx_kev
  #
  def export_as_openurl_ctx_kev(format = nil)
    super # TODO - OpenURL for non-MARC
  end

  # Export to RefWorks.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_refworks_marc_txt
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_refworks_marc_txt
  #
  def export_as_refworks_marc_txt
    super # TODO - RefWorks for non-MARC
  end

  # Export to EndNote.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_endnote
  #
  # Compare with:
  # @see Blacklight::Solr::Document::MarcExport#export_as_endnote
  #
  def export_as_endnote
    super # TODO - EndNote for non-MARC
  end

  # Export to Zotero RIS.
  #
  # @return [String]
  #
  # This method overrides:
  # @see Blacklight::Document::ExportExt#export_as_ris
  #
  def export_as_ris
    super # TODO - Zotero RIS for non-MARC
  end

  # ===========================================================================
  # :section: Blacklight::Document::SchemaOrgExt overrides
  # ===========================================================================

  public

  extend Blacklight::Document::SchemaOrgExt

  # :eds_document_type is a single-valued field.  If the value does not match
  # one of the keys then determination of the type defers to the publication
  # type.  Examples:
  #
  # 'Article'
  # 'Artikel'
  # 'Artikel<br>PeerReviewed'
  # 'Electronic Resource'
  # 'Journal'
  # 'Journal Article'
  # 'Poem'
  #
  DOC_TYPE_TO_SCHEMA_ORG = itemtype_mapping(
    'Advertising Review':   :Review,          # or :AdvertiserContentArticle
    Biography:              :Article,
    Book:                   :Book,
    'Book Chapter':         :Book,            # or :Chapter
    'Book in series':       :Review,
    'Book Review':          :Review,
    'Conference Report':    :Report,
    'Country Report':       :Book,            # or :Chapter
    Dissertation:           :Thesis,
    Interview:              :Article,
    'Letter to the Editor': :NewsArticle,     # or :OpinionNewsArticle
    Obituary:               :NewsArticle,     # or :ReportageNewsArticle
    Proceeding:             :Report,
    'Product Review':       :Review,          # or :ReviewNewsArticle,
    'Rapid Communication':  :Article,
    Review:                 :Review,
    'Review Article':       :ScholarlyArticle,
    Speech:                 :Report,
    'Table Of Contents':    :Article,
    Thesis:                 :Thesis,
    'Web Site Review':      :Review,
  ).freeze

  # :eds_publication_type_id is a single-valued field.  If the value does not
  # match one of the keys then the default is used.  Examples:
  #
  # 'Electronic Resource'
  # 'Unknown'
  #
  PUB_TYPE_TO_SCHEMA_ORG = itemtype_mapping(
    'Academic Journal':     :ScholarlyArticle,
    Audio:                  :Review,
    Book:                   :Book,
    Conference:             :Report,
    Dissertation:           :Thesis,
    'Dissertation/Thesis':  :Thesis,
    News:                   :NewsArticle,
    'Newspaper Article':    :NewsArticle,     # or :Newspaper
    Periodical:             :Article,
    'Primary Source':       :Report,
    Reference:              :Book,
    Review:                 :Review,
    'Serial Periodical':    :Article,
  ).freeze

  # itemtype
  #
  # @params [TrueClass, FalseClass, nil] peer_reviewed
  #
  # @return [String]
  #
  # TODO: This is undoubtedly incomplete...
  #
  # TODO: How does the data indicate the item was peer-reviewed?
  #
  def itemtype(peer_reviewed = nil)
    doc_type =
      itemtype_lookup(DOC_TYPE_TO_SCHEMA_ORG, :eds_document_type) ||
      itemtype_lookup(PUB_TYPE_TO_SCHEMA_ORG, :eds_publication_type_id)
    doc_type = :ScholarlyArticle if doc_type == :Article && peer_reviewed
    itemtype_table[doc_type] || super
  end

end

__loading_end(__FILE__)
