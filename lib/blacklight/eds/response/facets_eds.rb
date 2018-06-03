# lib/blacklight/eds/response/facets_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# EBSCO EDS version of
# @see Blacklight::Solr::Response::Facets
#
module Blacklight::Eds::Response::FacetsEds

  include Blacklight::Solr::Response::Facets

  # Represents a facet; which is a field and its values.
  #
  class FacetField < Blacklight::Solr::Response::Facets::FacetField

    # =========================================================================
    # :section: Blacklight::Solr::Response::Facets::FacetField overrides
    # =========================================================================

    public

    # limit
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#limit
    #
    def limit
      @options[:limit]  || eds_default_limit
    end

    # sort
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#sort
    #
    def sort
      @options[:sort]   || eds_default_sort
    end

    # offset
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#offset
    #
    def offset
      @options[:offset] || eds_default_offset
    end

    # prefix
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#prefix
    #
    def prefix
      @options[:prefix] || eds_default_prefix
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # eds_default_limit
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_limit
    #
    def eds_default_limit
      nil
    end

    # eds_default_sort
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_sort
    #
    def eds_default_sort
      solr_default_sort
    end

    # eds_default_offset
    #
    # @return [Integer, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_offset
    #
    def eds_default_offset
      solr_default_offset
    end

    # eds_default_prefix
    #
    # @return [String, nil]
    #
    # This method replaces:
    # @see Blacklight::Solr::Response::Facets::FacetField#solr_default_prefix
    #
    def eds_default_prefix
      solr_default_prefix
    end

  end

end

__loading_end(__FILE__)
