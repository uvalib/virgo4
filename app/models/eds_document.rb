# app/models/eds_document.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# A Blacklight::Document for items acquired from EBSCO Discovery Service.
#
# @see Blacklight::Eds::DocumentEds
# @see Blacklight::Document
#
class EdsDocument

  include Blacklight::Eds::DocumentEds

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
  # @example http://.../articles/:id?format=dc_xml
  # @example http://.../articles/:id?format=oai_dc_xml
  #
  # TODO: XML for search results could be OAI-PMH ListRecords response format
  # NOTE: At this time it's an invalid concatenation of :oai_dc elements.
  #
  use_extension(Blacklight::Document::DublinCore)

  # Email uses the semantic field mappings below to generate the body of an
  # email.
  use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS
  # text message.
  use_extension(Blacklight::Document::Sms)

  field_semantics.merge!(
    title:       :eds_title,
    author:      :eds_authors,
    language:    :eds_languages,
    format:      :eds_publication_type,
    # === For DublinCore ===
    #contributor: :xxx,
    #coverage:    :xxx,
    creator:     :eds_authors,
    date:        :eds_publication_date,
    #description: :eds_physical_description,
    identifier:  :id,
    #publisher:   :eds_publisher,
    #relation:    :xxx,
    #rights:      :xxx,
    #source:      :eds_source_title,
    subject:     :eds_subjects,
    #type:        :eds_document_type,
  )

end

__loading_end(__FILE__)
