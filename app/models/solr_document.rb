# app/models/solr_document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# A Blacklight::Document for items acquired from the Solr index service.
#
# @see Blacklight::Solr::Document
# @see LensDocument
#
class SolrDocument < LensDocument

  include Blacklight::Solr::Document
  include Blacklight::Solr::Document::Export
  include Blacklight::Solr::Document::SchemaOrg

  # ===========================================================================
  # :section: Extensions
  # ===========================================================================

  public

  # DublinCore uses the semantic field mappings below to assemble an
  # OAI-compliant Dublin Core document.  Fields may be multi- or single-valued.
  #
  # Recommendation: Use field names from Dublin Core
  #
  # @see Blacklight::Document::SemanticFields#field_semantics
  # @see Blacklight::Document::SemanticFields#to_semantic_values
  #
  # @example http://.../catalog/:id?format=dc_xml
  # @example http://.../catalog/:id?format=oai_dc_xml
  #
  # TODO: XML for search results could be OAI-PMH ListRecords response format
  # NOTE: At this time it's an invalid concatenation of :oai_dc elements.
  #
  use_extension(Blacklight::Document::DublinCore)

  # The following shows how to setup this Blacklight document to display
  # MARC documents.
  #
  # To make MARCXML the default format for "http://.../catalog/:id.xml", this
  # section has to come after DublinCore (or any other module which initializes
  # with `will_export_as(:xml)`).
  #
  # @example http://.../catalog/:id.xml                       MARCXML
  # @example http://.../catalog/:id?format=xml                MARCXML
  # @example http://.../catalog/:id?format=marcxml            MARCXML
  # @example http://.../catalog/:id?format=marc               MARC21
  # @example http://.../catalog/:id?format=refworks_marc_txt  RefWorks import
  # @example http://.../catalog/:id?format=endnote            Endnote import
  # @example http://.../catalog/:id?format=openurl_ctx_kev    OpenURL fragment
  #
  extension_parameters[:marc_source_field] = 'fullrecord'
  extension_parameters[:marc_format_type]  = :marcxml
  use_extension(Blacklight::Solr::Document::Marc) do |this_document|
    this_document.key?(extension_parameters[:marc_source_field])
  end

  # Email uses the semantic field mappings below to generate the body of an
  # email.
  use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS
  # text message.
  use_extension(Blacklight::Document::Sms)

  # ===========================================================================
  # :section: Semantic fields
  # ===========================================================================

  public

  field_semantics.merge!(
    title:        'title_a',     # TODO: 'title_vern_a' || 'title_a'
    author:       'author_a',
    language:     'language_a',
    format:       'format_a',
    # === For DublinCore ===
    #contributor: 'xxx',
    #coverage:    'xxx',
    creator:      'author_a',
    date:         'published_date',  # TODO: 'published_date' || 'published_daterange'
    #description: 'material_type_display',
    identifier:   'id',
    #publisher:   'published_display',
    #relation:    'xxx',
    #rights:      'xxx',
    #source:      'xxx',
    subject:      'subject_a',
    #type:        'xxx',
  )

  # ===========================================================================
  # :section: Blacklight::Document overrides
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, nil]                    source_doc
  # @param [RSolr::HashWithResponse, nil] response
  # @param [Symbol, nil]                  lens
  #
  # This method overrides:
  # @see Blacklight::Document#initialize
  #
  def initialize(source_doc = nil, response = nil, lens = nil)
    super(source_doc, response, lens)
  end

  # =========================================================================
  # :section: Blacklight::Document::Base overrides
  # =========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and not
  # discoverable).
  #
  # This method overrides:
  # @see Blacklight::Document::Base#hidden?
  #
  def hidden?
    super # TODO: Awaiting Solr field...
  end

  # Indicate whether this document can be discovered by user search.
  #
  # Such records, even if not independently discoverable can be linked to and
  # accessed directly.  This is useful in the case of records that are
  # "part of" a discoverable collection.
  #
  # This method overrides:
  # @see Blacklight::Document::Base#discoverable?
  #
  def discoverable?
    super # TODO: Awaiting Solr field...
  end

end

__loading_end(__FILE__)
