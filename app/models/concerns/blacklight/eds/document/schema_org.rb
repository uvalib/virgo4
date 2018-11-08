# app/models/concerns/blacklight/eds/document/schema_org.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../../lens/document/schema_org'

module Blacklight::Eds::Document

  # Blacklight::Eds::Document::SchemaOrg
  #
  # @see Blacklight::Lens::Document::SchemaOrg
  #
  module SchemaOrg

    include Blacklight::Lens::Document::SchemaOrg
    extend  Blacklight::Lens::Document::SchemaOrg

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

    # =========================================================================
    # :section: Blacklight::Lens::Document::SchemaOrg overrides
    # =========================================================================

    public

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

end

__loading_end(__FILE__)
