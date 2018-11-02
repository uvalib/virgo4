# app/models/concerns/blacklight/eds/document/export.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../document'
require_relative '../../lens/document/export'

module Blacklight::Eds::Document

  # Blacklight::Eds::Document::Export
  #
  # @see Blacklight::Lens::Document::Export
  #
  module Export

    include Blacklight::Lens::Document::Export

    # =========================================================================
    # :section: Blacklight::Lens::Document::Export overrides
    # =========================================================================

    public

    # Export in XML format.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Lens::Document::Export#export_as_xml
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
    # @see Blacklight::Lens::Document::Export#export_as_apa_citation_txt
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
    # @see Blacklight::Lens::Document::Export#export_as_mla_citation_txt
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
    # @see Blacklight::Lens::Document::Export#export_as_chicago_citation_txt
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
    # @see Blacklight::Lens::Document::Export#export_as_openurl_ctx_kev
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
    # @see Blacklight::Lens::Document::Export#export_as_refworks_marc_txt
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
    # @see Blacklight::Lens::Document::Export#export_as_endnote
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
    # @see Blacklight::Lens::Document::Export#export_as_ris
    #
    def export_as_ris
      super # TODO - Zotero RIS for non-MARC
    end

  end

end

__loading_end(__FILE__)
