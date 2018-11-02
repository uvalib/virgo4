# app/controllers/concerns/blacklight/lens/export.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Shared information about the names and types of export formats.
#
module Blacklight::Lens::Export

  extend ActiveSupport::Concern

  included do |base|
    __included(base, 'Blacklight::Lens::Export')
  end

  # A mapping of export name to export format type.
  #
  # @type [HashWithIndifferentAccess{Symbol=>Symbol}]
  #
  FORMATS = {
    refworks: :refworks_marc_txt,
    endnote:  :endnote,
    zotero:   :ris
  }.with_indifferent_access.freeze

  # A mapping of export format type to MIME type.
  #
  # @type [HashWithIndifferentAccess{Symbol=>String}]
  #
  MIME_TYPES = {
    openurl_ctx_kev:   'application/x-openurl-ctx-kev',
    refworks_marc_txt: 'text/plain',
    endnote:           'application/x-endnote-refer',
    ris:               'application/x-research-info-systems',
  }.with_indifferent_access.deep_freeze

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A mapping of export name to export format type.
  #
  # @return [HashWithIndifferentAccess{Symbol=>Symbol}]
  #
  def self.formats
    FORMATS
  end

  # A mapping of export format type to MIME type.
  #
  # @return [HashWithIndifferentAccess{Symbol=>String}]
  #
  def self.mime_types
    MIME_TYPES
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A mapping of export name to export format type.
  #
  # @return [Hash{Symbol=>Symbol}]
  #
  def export_format
    FORMATS
  end

  # A mapping of export format type to MIME type.
  #
  # @return [HashWithIndifferentAccess{Symbol=>String}]
  #
  def export_mime_type
    MIME_TYPES
  end

end

__loading_end(__FILE__)
