# app/models/solr_document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Ensure that MARC::XMLReader uses Nokogiri or other XML parser instead of the
# default (REXML).
require 'marc'
MARC::XMLReader.best_available!

# A Blacklight::Document for items acquired from the Solr index service.
#
# @see Blacklight::Solr::DocumentExt
# @see Blacklight::Solr::Document
# @see Blacklight::Document
#
class SolrDocument

  include Blacklight::Solr::DocumentExt

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
  extension_parameters[:marc_source_field] = :marc_display
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

  field_semantics.merge!(
    title:       :title_display, # TODO: :main_title_display || :title_display
    author:      :author_display,
    language:    :language_facet,
    format:      :format,
    # === For DublinCore ===
    #contributor: :xxx,
    #coverage:    :xxx,
    creator:     :author_display,
    date:        :pub_date,
    #description: :material_type_display,
    identifier:  :id,
    #publisher:   :published_display,
    #relation:    :xxx,
    #rights:      :xxx,
    #source:      :xxx,
    subject:     :subject_t,
    #type:        :xxx,
  )

end

__loading_end(__FILE__)
