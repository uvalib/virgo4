# app/services/blacklight/eds/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

module Blacklight::Eds

  # Blacklight::Eds::SearchService
  #
  # Returns search results from EBSCO Discovery Service.
  #
  # @see Blacklight::Eds::SearchHelperEds
  #
  class SearchService

    include Blacklight::RequestBuilders

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # blacklight_config
    #
    # @return [Blacklight::Configuration]
    #
    # == Usage Notes
    # This is required by Blacklight::RequestBuilders
    #
    attr_reader :blacklight_config

    # initialize
    #
    # @param [Blacklight::Configuration] bl_config
    # @param [Hash]                      user_params
    # @param [Hash]                      eds_params
    #
    # @option eds_params [ActionDispatch::Request::Session] :session
    # @option eds_params [Boolean]                          :guest
    #
    def initialize(bl_config, user_params = nil, eds_params = nil)
      @blacklight_config = bl_config
      @user_params = user_params || {}
      @eds_params  = eds_params  || {}
      repository_class = @blacklight_config.repository_class
      repository_class ||= Blacklight::Eds::Repository
      @repository = repository_class.new(@blacklight_config)
    end

    # =========================================================================
    # :section: Blacklight::SearchHelper replacements
    # =========================================================================

    public

    # Get results from the search service.
    #
    # @yield [search_builder]         Optional block yields configured
    #                                   SearchBuilder, caller can modify or
    #                                   create new SearchBuilder to be used.
    #                                   Block should return SearchBuilder to be
    #                                   used.
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#search_results
    #
    def search_results
      page = @user_params[:page]
      rows = @user_params[:per_page] || @user_params[:rows]

      query = search_builder.with(@user_params)
      query.page = page if page
      query.rows = rows if rows
      query = yield(query) if block_given?

      response = @repository.search(query, @eds_params)
      if response.grouped? && grouped_key_for_results
        return response.group(grouped_key_for_results), []
      elsif response.grouped? && response.grouped.length == 1
        return response.grouped.first, []
      else
        return response, response.documents
      end
    end

    # Retrieve a document, given the doc id.
    #
    # @param [String, Array<String>] id
    # @param [Hash]                  eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, EdsDocument)>]
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#fetch
    #
    def fetch(id = nil, eds_params = nil)
      if id.is_a?(Array)
        fetch_many(id, nil, eds_params)
      else
        fetch_one(id, eds_params)
      end
    end

    # Get the search service response when retrieving a single facet field.
    #
    # @param [String, Symbol] facet_field
    # @param [Hash]           req_params
    # @param [Hash]           eds_params
    #
    # @return [Blacklight::Solr::Response]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#get_facet_field_response
    #
    def get_facet_field_response(facet_field, req_params = nil, eds_params = nil)
      query =
        search_builder
          .with(@user_params)
          .facet(facet_field)
          .merge(req_params || {})
      @repository.search(query, @eds_params.merge(eds_params || {}))
    end

    # Get the previous and next document from a search result.
    #
    # @param [Integer] index
    # @param [Hash]    req_params
    # @param [Hash]    user_params
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#get_previous_and_next_documents_for_search
    #
    def get_previous_and_next_documents_for_search(index, req_params, user_params = nil)
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
      eds_params = @eds_params.merge('previous-next-index': next_index)
      response = @repository.search(query, eds_params)
      docs     = response.documents
      prev_doc = (docs.first if index > 0)
      next_doc = (docs.last  if next_index < response.total)
      return response, [prev_doc, next_doc]
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
    # Compare with:
    # @see Blacklight::SearchHelper#get_opensearch_response
    #
    def get_opensearch_response(field = nil, req_params = nil, eds_params = nil)
      field ||= @blacklight_config.view_config(:opensearch).title_field
      query =
        search_builder
          .with(@user_params)
          .merge(solr_opensearch_params(field))
          .merge(req_params || {})
      resp = @repository.search(query, @eds_params.merge(eds_params || {}))
      q    = resp.params[:q].to_s
      docs = resp.documents.flat_map { |doc| doc[field] }.compact.uniq
      return q, docs
    end

    # The key to use to retrieve the grouped field to display.
    #
    # @return [?]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#grouped_key_for_results
    #
    def grouped_key_for_results
      @blacklight_config.index.group
    end

    # repository
    #
    # @return [Blacklight::Eds::Repository]
    #
    # Compare with:
    # @see Blacklight::SearchHelper#repository
    #
    def repository
      @repository
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # fetch_fulltext
    #
    # @param [String] id
    # @param [String] type
    # @param [Hash]   req_params
    #
    # @return [String]
    #
    def fetch_fulltext(id, type, req_params)
      @repository.fulltext_url(id, type, req_params, @eds_params)
    end

    # =========================================================================
    # :section: Blacklight::SearchHelper replacements
    # =========================================================================

    public

    # Retrieve a set of documents by id.
    #
    # @param [Array] ids
    # @param [Hash]  req_params
    # @param [Hash]  eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
    #
    # Compare with (for catalog search):
    # @see Blacklight::SearchHelperExt#fetch_many
    #
    def fetch_many(ids, req_params = nil, eds_params = nil)

      # Get each item from its appropriate repository one-at-a-time rather than
      # as a batch (search) request.  This is for two reasons:
      # 1. Ensure that each failed item is indicated with a *nil* value.
      # 2. To better support cache management.
      response_hash = {}
      response_docs = {}
      Array.wrap(ids).each do |id|
        next if response_hash[id] && response_docs[id]
        response, document = fetch_one(id, eds_params)
        response &&= response['response']
        response &&= response['doc'] || response['docs']
        response_hash[id] = Array.wrap(response).first || document&.to_h
        response_docs[id] = document
      end

      # Manufacture a response from the sets of document hash values.
      response_params = Blacklight::Parameters.sanitize(req_params)
      response = Blacklight::Eds::Response.new({}, response_params)
      response['response'] ||= {}
      response['response']['docs'] = response_hash.values
      return response, response_docs.values

    end

    # fetch_one
    #
    # @param [?]    id
    # @param [Hash] eds_params
    #
    # @return [Array<(Blacklight::Solr::Response, EdsDocument)>]
    #
    # Compare with (for catalog search):
    # @see Blacklight::SearchHelperExt#fetch_one
    #
    def fetch_one(id, eds_params = nil)
      eds_params = @eds_params.merge(eds_params || {})
      response   = @repository.find(id, nil, eds_params)
      return response, response.documents.first
    end
  end

end

__loading_end(__FILE__)
