# app/models/concerns/blacklight/solr/document/schema_org.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../../lens/document/schema_org'

module Blacklight::Solr::Document

  # Blacklight::Solr::Document::SchemaOrg
  #
  # @see Blacklight::Lens::Document::SchemaOrg
  #
  module SchemaOrg

    include Blacklight::Lens::Document::SchemaOrg
    extend  Blacklight::Lens::Document::SchemaOrg

    # :format_f is a multi-valued field; the entries in this mapping are in
    # order of precedence.
    FORMAT_FACET_TO_SCHEMA_ORG = itemtype_mapping(
      Dataset:                :Dataset,
      'Conference Paper':     :Report,
      'Technical Report':     :Report,
      'Thesis/Dissertation':  :Thesis,
      Article:                :Periodical,
      'Journal/Magazine':     :Periodical,
      Newspaper:              :Periodical, # or :Newspaper
      Periodical:             :Periodical,
      'Blu-Ray':              :Movie,
      DVD:                    :Movie,
      Film:                   :Movie,
      Laserdisc:              :Movie,
      'Online Video':         :Movie,
      'Streaming Video':      :Movie,
      VHS:                    :Movie,
      Video:                  :Movie,
      CD:                     :MusicRecording,
      Cartridge:              :MusicRecording,
      Cassette:               :MusicRecording,
      Cylinder:               :MusicRecording,
      LP:                     :MusicRecording,
      'Sound Recording':      :MusicRecording,
      'Streaming Audio':      :MusicRecording,
      'Tape Reel':            :MusicRecording,
      Coin:                   :Photograph,
      Photographs:            :Photograph,
      'Physical Object':      :Photograph,
      Globe:                  :Map,
      Map:                    :Map,
      Atlas:                  :Book,
      Book:                   :Book,
    ).freeze

    # =========================================================================
    # :section: Blacklight::Lens::Document::SchemaOrg overrides
    # =========================================================================

    public

    # itemtype
    #
    # @return [String]
    #
    def itemtype
      doc_type = itemtype_lookup(FORMAT_FACET_TO_SCHEMA_ORG, :format_f)
      itemtype_table[doc_type] || super
    end

  end

end

__loading_end(__FILE__)
