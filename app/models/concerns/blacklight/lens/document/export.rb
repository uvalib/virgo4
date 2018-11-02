# app/models/concerns/blacklight/lens/document/export.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../document'

module Blacklight::Lens::Document

  # Extensions to Blacklight::Document::Export.
  #
  # The document class that includes this module should override these methods
  # according to its abilities.
  #
  # (For example, SolrDocument overrides these when [conditionally] including
  # Blacklight::Solr::Document::Marc.)
  #
  # @see Blacklight::Document::Export
  # @see Blacklight::Solr::Document::MarcExport
  #
  module Export

    include Blacklight::Solr::Document::Marc unless ONLY_FOR_DOCUMENTATION

    include Blacklight::Document::Export

    # =========================================================================
    # :section: Blacklight::Solr::Document::Marc default implementations
    # =========================================================================

    public

    # Translate a document's metadata to MARC.
    #
    # @return [MARC::Record]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::Marc#to_marc
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def to_marc
      nil
    end

    # =========================================================================
    # :section: Blacklight::Solr::Document::Marc default implementations
    # =========================================================================

    protected

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
      nil
    end

    # =========================================================================
    # :section: Blacklight::Solr::Document::MarcExport default implementations
    # =========================================================================

    public

    # Export in MARC format.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_marc
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_marc
      if has_marc?
        not_implemented("MARC [#{self.class}]")
      else
        invalid_for_non_marc(__method__) # TODO: ???
      end
    end

    # Export in MARCXML format.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_marcxml
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_marcxml
      if has_marc?
        not_implemented("MARCXML [#{self.class}]")
      else
        invalid_for_non_marc(__method__) # TODO: ???
      end
    end

    # Export in XML format.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_xml
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_xml
      not_implemented("XML [#{self.class}]")
    end

    # Emit an APA (American Psychological Association) bibliographic citation.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_apa_citation_txt
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_apa_citation_txt
      not_implemented("APA citation [#{self.class}]")
    end

    # Emit an MLA (Modern Language Association) bibliographic citation.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_mla_citation_txt
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_mla_citation_txt
      not_implemented("MLA citation [#{self.class}]")
    end

    # Emit an CMOS (Chicago Manual of Style) bibliographic citation.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_chicago_citation_txt
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_chicago_citation_txt
      not_implemented("CMOS citation [#{self.class}]")
    end

    # Export as an OpenURL KEV (key-encoded value) query string.
    #
    # @param [String] format
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_openurl_ctx_kev
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_openurl_ctx_kev(format = nil)
      not_implemented("OpenURL [#{self.class}]")
    end

    # Export to RefWorks.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_refworks_marc_txt
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_refworks_marc_txt
      not_implemented("RefWorks [#{self.class}]")
    end

    # Export to EndNote.
    #
    # @return [String]
    # @return [nil]
    #
    # Compare with:
    # @see Blacklight::Solr::Document::MarcExport#export_as_endnote
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_endnote
      not_implemented("EndNote [#{self.class}]")
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Export to Zotero RIS.
    #
    # @return [String]
    # @return [nil]
    #
    # == Usage Notes
    # The including class should override this method as needed.
    #
    def export_as_ris
      not_implemented("Zotero RIS [#{self.class}]")
    end

    # Indicate whether the document includes MARC metadata.
    #
    def has_marc?
      to_marc.present?
    end

    # =========================================================================
    # :section: Synonyms
    # =========================================================================

    public

    def export_as_apa_citation;     export_as_apa_citation_txt     end
    def export_as_mla_citation;     export_as_mla_citation_txt     end
    def export_as_chicago_citation; export_as_chicago_citation_txt end
    def export_as_openurl;          export_as_openurl_ctx_kev      end
    def export_as_refworks;         export_as_refworks_marc_txt    end
    def export_as_zotero;           export_as_ris                  end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    PROD_EXPORT_NOT_AVAILABLE =
      'Export as %s not available for non-MARC metadata' \
      ' - Blacklight does not support it'.html_safe.freeze
    DEV_EXPORT_NOT_AVAILABLE = PROD_EXPORT_NOT_AVAILABLE

    # Result to return from the base method implementation.
    #
    # To cause `NotImplementedError` to be raised instead, make this value *nil*.
    #
    EXPORT_NOT_AVAILABLE =
      case Rails.env
        when 'production'  then PROD_EXPORT_NOT_AVAILABLE
        when 'development' then DEV_EXPORT_NOT_AVAILABLE
        else                    NotImplementedError
      end

    # not_implemented
    #
    # @param [Array] *args
    #
    # @return [String]
    # @return [nil]
    #
    # @raise [NotImplementedError]    As defined by self#EXPORT_NOT_AVAILABLE.
    #
    def not_implemented(*args)
      error = EXPORT_NOT_AVAILABLE
      raise error   if error.is_a?(Exception)
      error %= args if error.is_a?(String) && args.present?
      error
    end

    # invalid_for_non_marc
    #
    # @param [Symbol, nil] method
    #
    # @raise [NotImplementedError]
    #
    def invalid_for_non_marc(method = nil)
      report = +'ERROR: '
      report << method.inspect << ' ' if method
      report << 'SHOULD NEVER BE INVOKED FOR NON-MARC'
      raise NotImplementedError, report
    end

  end

end

__loading_end(__FILE__)
