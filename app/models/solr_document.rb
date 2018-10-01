# frozen_string_literal: true
class SolrDocument
  include Blacklight::Solr::Document

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

  field_semantics.merge!(
    title:       :title_t, # TODO: :main_title_display || :title_display
    author:      :author_t,
    language:    :language_facet,
    format:      :format_t,
    language:    :language_a,
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
