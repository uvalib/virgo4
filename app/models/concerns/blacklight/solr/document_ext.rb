# app/models/concerns/blacklight/eds/suggest/response_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'
require 'blacklight/solr/document'

# Blacklight::Solr::DocumentExt
#
# @see Blacklight::Solr::Document
#
module Blacklight::Solr::DocumentExt

  extend ActiveSupport::Concern

  include Blacklight::Solr::Document
  include Blacklight::DocumentExt

  # ===========================================================================
  # :section: Blacklight::DocumentExt overrides
  # ===========================================================================

  public

  # Indicate whether this document is shadowed (that is, not viewable and
  # not discoverable).
  #
  # This method overrides:
  # @see Blacklight::DocumentExt#hidden?
  #
  def hidden?
    has?(:shadowed_location_facet, 'HIDDEN')
  end

  # Indicate whether this document can be discovered by user search.
  #
  # Such records, even if not independently discoverable can be linked to and
  # accessed directly.  This is useful in the case of records that are
  # "part of" a discoverable collection.
  #
  # This method overrides:
  # @see Blacklight::DocumentExt#discoverable?
  #
  def discoverable?
    !has?(:shadowed_location_facet, 'UNDISCOVERABLE')
  end

  # ===========================================================================
  # :section: Blacklight::Document::SchemaOrgExt overrides
  # ===========================================================================

  public

  extend Blacklight::Document::SchemaOrgExt

  # :format_facet is a multi-valued field; the entries in this mapping are in
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

  # itemtype
  #
  # @return [String]
  #
  def itemtype
    doc_type = itemtype_lookup(FORMAT_FACET_TO_SCHEMA_ORG, :format_facet)
    itemtype_table[doc_type] || super
  end

end

__loading_end(__FILE__)
