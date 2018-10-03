# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document

  extension_parameters[:marc_source_field] = :fullrecord
  extension_parameters[:marc_format_type]  = :marcxml

  use_extension( Blacklight::Solr::Document::Marc) do |document|
    document.key?(extension_parameters[:marc_source_field])
  end

  field_semantics.merge!(
    title:    'title_a',
    author:   'author_a',
    language: 'language_a',
    format:   'format_a'
  )

  # self.unique_key = 'id'

  # Email uses the semantic field mappings below to generate the body of an email.
  SolrDocument.use_extension(Blacklight::Document::Email)

  # SMS uses the semantic field mappings below to generate the body of an SMS email.
  SolrDocument.use_extension(Blacklight::Document::Sms)

  # DublinCore uses the semantic field mappings below to assemble an OAI-compliant Dublin Core document
  # Semantic mappings of solr stored fields. Fields may be multi or
  # single valued. See Blacklight::Document::SemanticFields#field_semantics
  # and Blacklight::Document::SemanticFields#to_semantic_values
  # Recommendation: Use field names from Dublin Core
  use_extension(Blacklight::Document::DublinCore)

end
