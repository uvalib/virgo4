# app/models/concerns/blacklight/solr/document/export.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../../lens/document/export'

# Ensure that MARC::XMLReader uses Nokogiri or other XML parser instead of the
# default (REXML).
require 'marc'
MARC::XMLReader.best_available!

module Blacklight::Solr::Document

  # Blacklight::Solr::Document::Export
  #
  # @see Blacklight::Lens::Document::Export
  #
  module Export

    include Blacklight::Lens::Document::Export
    include Blacklight::Solr::Document::Marc
    include Blacklight::Solr::Document::MarcExport

    # =========================================================================
    # :section: Blacklight::Lens::Document::Export overrides
    # =========================================================================

    public

    # Export in XML format.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_xml
    #
    def export_as_xml
      if has_marc?
        super
      else
        not_implemented("XML [#{self.class}]") # TODO: XML for non-MARC
      end
    end

    # Emit an APA (American Psychological Association) bibliographic citation
    # from the :citation_apa field.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_apa_citation_txt
    #
    def export_as_apa_citation_txt
      if has_marc?
        super
      else
        not_implemented("APA citation [#{self.class}]") # TODO: APA for non-MARC
      end
    end

    # Emit an MLA (Modern Language Association) bibliographic citation from the
    # :citation_mla field.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_mla_citation_txt
    #
    def export_as_mla_citation_txt
      if has_marc?
        super
      else
        not_implemented("MLA citation [#{self.class}]") # TODO: MLA for non-MARC
      end
    end

    # Emit an CMOS (Chicago Manual of Style) bibliographic citation from the
    # :citation_chicago field.
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_chicago_citation_txt
    #
    def export_as_chicago_citation_txt
      if has_marc?
        super
      else
        not_implemented("CMOS citation [#{self.class}]") # TODO: CMOS for non-MARC
      end
    end

    # Exports as an OpenURL KEV (key-encoded value) query string.
    #
    # @param [String] format
    #
    # @return [ActiveSupport::SafeBuffer]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_openurl_ctx_kev
    #
    def export_as_openurl_ctx_kev(format = nil)
      if has_marc?
        super
      else
        not_implemented("OpenURL [#{self.class}]") # TODO: OpenURL for non-MARC
      end
    end

    # Export to RefWorks.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_refworks_marc_txt
    #
    def export_as_refworks_marc_txt
      if has_marc?
        super
      else
        not_implemented("RefWorks [#{self.class}]") # TODO: RefWorks for non-MARC
      end
    end

    # Export to EndNote.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Solr::Document::MarcExport#export_as_endnote
    #
    def export_as_endnote
      if has_marc?
        super
      else
        not_implemented("EndNote [#{self.class}]") # TODO: EndNote for non-MARC
      end
    end

    # Export to Zotero RIS.
    #
    # @return [String]
    #
    # This method overrides:
    # @see Blacklight::Lens::Document::Export#export_as_ris
    #
    def export_as_ris
      if has_marc?
        super
      else
        not_implemented("Zotero RIS [#{self.class}]") # TODO: Zotero RIS for non-MARC
      end
    end

    # Indicate whether the document includes MARC metadata.
    #
    # This method overrides:
    # @see Blacklight::Lens::Document::Export#has_marc?
    #
    def has_marc?
      to_marc.present?
    end

    # =========================================================================
    # :section: Blacklight::Lens::Document::Export overrides
    # =========================================================================

    protected

    # Get a document's MARC metadata field.
    #
    # @return [MARC::Record, nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::Marc#marc_source
    #
    def marc_source
      @_marc_source ||= fetch(_marc_source_field, nil)
    end

    # Generate MARC from a document's metadata.
    #
    # @return [MARC::Record]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::Marc#load_marc
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def load_marc
      super if marc_source.present?
    end

  end

end

__loading_end(__FILE__)
