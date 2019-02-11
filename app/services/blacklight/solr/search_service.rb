# app/services/blacklight/solr/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight/solr'

module Blacklight::Solr

  # Blacklight::Solr::SearchService
  #
  # Returns search results from a Solr index service.
  #
  # @see Blacklight::Lens::SearchService
  #
  class SearchService < Blacklight::Lens::SearchService

    # =========================================================================
    # :section: Blacklight::SearchService overrides
    # =========================================================================

    public

    # Get the previous and next document from a search result.
    #
    # @param [Integer]   index
    # @param [Hash]      req_params
    # @param [Hash, nil] other_params
    #
    # @return [Array<(Blacklight::Solr::Response, Array<SolrDocument)>)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#previous_and_next_documents_for_search
    #
    def previous_and_next_documents_for_search(
      index,
      req_params,
      other_params = nil
    )
      pagination_params = previous_and_next_document_params(index)
      start = pagination_params.delete(:start)
      rows  = pagination_params.delete(:rows)
      query =
        search_builder
          .with(req_params)
          .start(start)
          .rows(rows)
          .merge(other_params || {})
          .merge(pagination_params)
          .except(:add_facetting_to_solr, :add_facet_paging_to_solr)

      # Get the previous, current and next documents.
      response = repository.search(query)

      # Previous or next document will be *nil* at the ends of results.
      docs     = response.documents
      prev_doc = (docs.first if index > 0)
      next_doc = (docs.last  if index < (response.total - 1))
      return response, [prev_doc, next_doc]
    end

  end

end

__loading_end(__FILE__)
