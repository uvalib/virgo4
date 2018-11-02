# app/services/blacklight/lens/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module Blacklight::Lens

  # Blacklight::Lens::SearchService
  #
  # Returns search results from an index search service.
  #
  # @see Blacklight::SearchService
  #
  # == Implementation Notes
  # The base class assumes that the search service is based on Solr.
  #
  class SearchService < Blacklight::SearchService

    include Blacklight::Lens

    # =========================================================================
    # :section: Blacklight::SearchService overrides
    # =========================================================================

    public

    # initialize
    #
    # @param [Blacklight::Configuration] config
    # @param [Hash, nil]                 usr_params
    # @param [Hash, nil]                 context
    #
    # @option eds_params [ActionDispatch::Request::Session] :session
    # @option eds_params [Boolean]                          :guest
    #
    # @see Blacklight::SearchService#initialize
    #
    def initialize(config, usr_params = nil, context = nil)
      usr_params ||= {}
      super(config, usr_params)
      @context = context || {}
      @context[:service_params] ||= {}
    end

    # Retrieve one or more documents.
    #
    # @param [String, Array<String>] id
    # @param [Hash, nil]             other_params
    #
    # @return [Array<(Blacklight::Lens::Response, Blacklight::Document)>]
    # @return [Array<(Blacklight::Lens::Response, Array<Blacklight::Document>)>]
    #
    def fetch(id, other_params = nil)
      other_params ||= {}
      if !polymorphic?
        super(id, other_params)
      elsif id.is_a?(Array)
        polymorphic_fetch_many(id, other_params)
      else
        polymorphic_fetch_one(id, other_params)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Indicate whether the search service has been created to make generic
    # requests via the specific search service(s) appropriate to the requested
    # item(s).
    #
    def polymorphic?
      request.present?
    end

    # Fetch one document using the proper search service.
    #
    # If *id* ends with "/LENS" then that portion is removed and interpreted as
    # the lens context; if *id* is just the document identifier, the lens
    # context will be determine by the nature of the identifier alone.
    #
    # @param [String]    id
    # @param [Hash, nil] other_params
    #
    # @return [Array<(Blacklight::Lens::Response, Blacklight::Document)>]
    #
    # Compare with (for catalog search):
    # @see Blacklight::Solr::SearchService#fetch_one
    #
    def polymorphic_fetch_one(id, other_params = nil)
      search = user_params
      ctx    = context.except(:request)
      controller_instance(id) do |id|
        self.search_service(search, ctx).fetch(id, other_params)
      end
    end

    # Retrieve a set of documents by id, each from the appropriate repository.
    #
    # @param [Array<String>] ids
    # @param [Hash, nil]     other_params
    #
    # @return [Array<(Blacklight::Lens::Response, Array<Blacklight::Document>)>]
    #
    # Compare with (for catalog search):
    # @see Blacklight::Solr::SearchService#fetch_many
    #
    def polymorphic_fetch_many(ids, other_params = nil)
      ids       = Array.wrap(ids)
      documents = ids.map { |id| polymorphic_fetch_one(id, other_params).last }
      response  = construct_response(documents)
      [response, response.documents]
    end

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # All information about the search apart from the search parameters
    # themselves.
    #
    # @return [Hash]
    #
    attr_reader :context

    # Parameters passed to the service (as opposed to the search parameters
    # which are passed to the repository).
    #
    # @return [Hash]
    #
    def service_params
      context[:service_params]
    end

    # The representation of the user performing the search.
    #
    # @return [User, nil]
    #
    def user
      context[:user]
    end

    # For polymorphic searches.
    #
    # @return [ActionDispatch::Request, nil]
    #
    def request
      context[:request]
    end

    # Supply a block in the context of the proper lens controller to process
    # the requested item based on its identity.
    #
    # @param [String, Hash, SearchBuilder] object
    #
    # @yield [doc_id]
    # @yieldparam [String] doc_id     ID of the requested document.
    # @yieldreturn [Array<(Blacklight::Lens::Response, Object)>]
    #
    # @return [Array<(Blacklight::Lens::Response, Object)>]
    #
    def controller_instance(object, &block)
      id, lens =
        if object.is_a?(Hash)
          [object[:id], object[:lens]]
        else
          object.to_s
        end
      id, lens = id.split('/') unless lens.present?
      lens_entry(lens || id).instance(nil, request).instance_exec(id, &block)
    end

    # Create a Response object from a set of Documents.
    #
    # @param [Array<Blacklight::Document>] docs
    # @param [Hash, nil]                   params
    # @param [Hash, nil]                   options
    #
    # @return [Blacklight::Lens::Response]
    #
    def construct_response(docs, params = nil, options = nil)
      data = {
        responseHeader: { status: 0 },
        response:       { docs:   Array.wrap(docs).map(&:to_h) }
      }
      params  ||= Blacklight::Parameters.sanitize(user_params)
      options ||= { documents: docs, blacklight_config: blacklight_config }
      blacklight_config.response_model.new(data, params, options)
    end

  end

end

__loading_end(__FILE__)
