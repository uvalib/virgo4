# app/services/blacklight/eds/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'
require_relative '../lens/search_service'

module Blacklight::Eds

  # Blacklight::Eds::SearchService
  #
  # Returns search results from EBSCO Discovery Service.
  #
  # @see Blacklight::Lens::SearchService
  #
  class SearchService < Blacklight::Lens::SearchService

    # =========================================================================
    # :section: Blacklight::SearchService overrides
    # =========================================================================

    public

    # initialize
    #
    # @param [Hash] args              Keyword parameters passed to super.
    #
    # @option args [Blacklight::Configuration] :config Required.
    # @option args [Hash]   :user_params            Default: {}
    # @option args [Class]  :search_builder_class   Default:
    #                                               config.search_builder_class
    # @option args [Hash]   :context                Default: {}
    #
    # @option user_params [ActionDispatch::Request::Session] :session
    # @option user_params [Boolean]                          :guest
    #
    # This method overrides:
    # @see Blacklight::Lens::SearchService#initialize
    #
    def initialize(**args)
      super(args)
      eds_params = user_params.extract!(*EDS_PARAMS)
      context[:service_params].merge!(eds_params)
    end

    # Get results from the search service.
    #
    # @yield [search_builder]         Optional block yields configured
    #                                   SearchBuilder, caller can modify or
    #                                   create new SearchBuilder to be used.
    #                                   Block should return SearchBuilder to be
    #                                   used.
    #
    # @return [Array<(Blacklight::Eds::Response, Array<EdsDocument>)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#search_results
    #
    def search_results
      page = user_params[:page]
      rows = user_params[:per_page] || user_params[:rows]

      query = search_builder.with(user_params)
      query.page = page if page
      query.rows = rows if rows
      query = yield(query) if block_given?

      response  = repository.search(query, service_params)
      documents = []
      if response.grouped? && grouped_key_for_results
        response  = response.group(grouped_key_for_results)
      elsif response.grouped? && response.grouped.length == 1
        response  = response.grouped.first
      else
        documents = response.documents
      end
      [response, documents]
    end

    # Get the search service response when retrieving a single facet field.
    #
    # @param [String, Symbol] facet_field
    # @param [Hash]           req_params
    # @param [Hash]           eds_params
    #
    # @return [Blacklight::Eds::Response]
    #
    # This method overrides:
    # @see Blacklight::SearchService#facet_field_response
    #
    def facet_field_response(facet_field, req_params = nil, eds_params = nil)
      query =
        search_builder
          .with(user_params)
          .facet(facet_field)
          .merge(req_params || {})
      eds_params = service_params.merge(eds_params || {})
      repository.search(query, eds_params)
    end

    # Get the previous and next document from a search result.
    #
    # @param [Integer] index
    # @param [Hash]    req_params
    # @param [Hash]    user_params
    #
    # @return [Array<(Blacklight::Eds::Response, Array<EdsDocument>)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#previous_and_next_documents_for_search
    #
    def previous_and_next_documents_for_search(index, req_params, user_params = nil)
      pagination_params = previous_and_next_document_params(index)
      start = pagination_params.delete(:start)
      rows  = pagination_params.delete(:rows)
      query =
        search_builder
          .with(req_params)
          .start(start)
          .rows(rows)
          .merge(user_params || {})
          .merge(pagination_params)
      # Add an EDS current page index for next-previous search.
      next_index = index + 1
      eds_params = service_params.merge('previous-next-index': next_index)
      response = repository.search(query, eds_params)
      docs     = response.documents
      prev_doc = (docs.first if index > 0)
      next_doc = (docs.last  if next_index < response.total)
      [response, [prev_doc, next_doc]]
    end

    # A solr query method.
    #
    # Does a standard search but returns a simplified object.
    #
    # An array is returned, the first item is the query string, the second item
    # is an other array. This second array contains all of the field values for
    # each of the documents...
    # where the field is the "field" argument passed in.
    #
    # @param [?]    field
    # @param [Hash] req_params
    # @param [Hash] eds_params
    #
    # @return [Array<(String, Array<EdsDocument>)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#opensearch_response
    #
    def opensearch_response(field = nil, req_params = nil, eds_params = nil)
      field ||= blacklight_config.view_config(:opensearch).title_field
      query =
        search_builder
          .with(user_params)
          .merge(solr_opensearch_params(field))
          .merge(req_params || {})
      eds_params = service_params.merge(eds_params || {})
      response = repository.search(query, eds_params)
      q    = response.params[:q].to_s
      docs = response.documents.flat_map { |doc| doc[field] }.compact.uniq
      [q, docs]
    end

    # Generate a SearchBuilder instance.
    #
    # @return [SearchBuilderEds]
    #
    # This method overrides:
    # @see Blacklight::SearchService#search_builder
    #
    # == Implementation Notes
    # This is here for debugging purposes; it can be safely removed.
    #
    def search_builder
      super.tap do |result|
        unless result.is_a?(::SearchBuilderEds)
          raise "#{result.class} should be SearchBuilderEds"
        end
      end
    end

    # Generate a Repository instance.
    #
    # @return [Blacklight::Eds::Repository]
    #
    # This method overrides:
    # @see Blacklight::SearchService#repository
    #
    # == Implementation Notes
    # There is actually a problem with the base method when called via
    # #generic_fetch_one because it seems to be referencing blacklight_config
    # of the original context.  Even `blacklight_config.repository` from
    # here gives the wrong result.
    #
    def repository
      super.tap do |result|
        unless result.is_a?(Blacklight::Eds::Repository)
          raise "#{result.class} should be Blacklight::Eds::Repository"
        end
      end
    end

    # =========================================================================
    # :section: Blacklight::SearchService overrides
    # =========================================================================

    private

    # fetch_one
    #
    # @param [?]    id
    # @param [Hash] eds_params
    #
    # @return [Array<(Blacklight::Eds::Response, EdsDocument)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#fetch_one
    #
    def fetch_one(id, eds_params = nil)
      eds_params = service_params.merge(eds_params || {})
      response   = repository.find(id, nil, eds_params)
      [response, response.documents.first]
    end

    # Retrieve a set of documents by id.
    #
    # Get each item one-at-a-time rather than as a batch (search) request.
    # This is for two reasons:
    # 1. Ensure that each failed item is indicated with a *nil* value.
    # 2. To better support cache management.
    #
    # @param [Array] ids
    # @param [Hash]  eds_params
    #
    # @return [Array<(Blacklight::Lens::Response, Array<Blacklight::Document>)>]
    #
    # This method overrides:
    # @see Blacklight::SearchService#fetch_many
    #
    def fetch_many(ids, eds_params = nil)
      ids       = Array.wrap(ids)
      documents = ids.map { |id| fetch_one(id, eds_params).last }
      response  = construct_response(documents)
      [response, response.documents]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    def session
      context[:session] || {}
    end

    def session_token
      context[:session_token]
    end

    def guest
      context[:guest]
    end

    def authenticated
      context[:authenticated]
    end

    # fetch_fulltext
    #
    # @param [String] id
    # @param [String] type
    # @param [Hash]   req_params
    #
    # @return [String]
    #
    def fetch_fulltext(id, type, req_params)
      repository.fulltext_url(id, type, req_params, service_params)
    end

  end

end

__loading_end(__FILE__)
