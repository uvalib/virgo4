# app/controllers/concerns/blacklight/eds/search_helper_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::SearchHelperExt for controllers that work with
# articles (EdsDocument).
#
# @see Blacklight::SearchHelperExt
# @see Blacklight::SearchHelper
#
# == Implementation Notes
# The SearchHelper overrides in this module are essentially a pass-through for:
# @see Blacklight::Eds::SearchService
#
module Blacklight::Eds::SearchHelperEds

  extend ActiveSupport::Concern

  include Blacklight::ConfigurableExt
  include Blacklight::SearchHelperExt

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::Eds::SearchHelperEds')

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Get results from the search service.
  #
  # @param [Hash] user_params
  # @param [Hash] eds_params
  #
  # @return [Blacklight::Eds::SearchService]
  #
  def search_service(user_params = nil, eds_params = nil)
    u_params = search_state.to_h
    u_params.merge!(user_params) if user_params.present?
    e_params = {
      # Extracted by Blacklight::Eds::Repository#eds_init
      session:       session,
      authenticated: !current_or_guest_user.guest,

      # Passed on to the EBSCO EDS API
      guest:         session[:guest],
      session_token: session[:eds_session_token],
    }
    e_params.merge!(eds_params) if eds_params.present?
    Blacklight::Eds::SearchService.new(blacklight_config, u_params, e_params)
  end

  # fetch_fulltext
  #
  # @param [String] id
  # @param [String] type
  # @param [Hash]   req_params
  #
  # @return [String]
  #
  # @see Blacklight::Eds::SearchService#fetch_fulltext
  #
  def fetch_fulltext(id, type, req_params = nil)
    search_service.fetch_fulltext(id, type, req_params)
  end

  # ===========================================================================
  # :section: Blacklight::SearchHelperExt overrides
  # ===========================================================================

  public

  # search_results
  #
  # @param [Hash] user_params
  # @param [Hash] eds_params
  #
  # @yield [search_builder]           Optional block yields configured
  #                                     SearchBuilder, caller can modify or
  #                                     create new SearchBuilder to be used.
  #                                     Block should return SearchBuilder to be
  #                                     used. # TODO: ???
  #
  # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#search_results
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#search_results
  #
  def search_results(user_params = nil, eds_params = nil)
    user_params ||= params.to_unsafe_h
    search_service(user_params, eds_params).search_results
  end

  # Get the search service response when retrieving only a single facet field.
  #
  # @param [String, Symbol] facet_field
  # @param [Hash]           req_params
  # @param [Hash]           eds_params
  #
  # @return [Blacklight::Solr::Response]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#get_facet_field_response
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#get_facet_field_response
  #
  def get_facet_field_response(facet_field, req_params = nil, eds_params = nil)
    search_service.get_facet_field_response(
      facet_field,
      (req_params || params),
      eds_params
    )
  end

  # Get the previous and next document from a search result.
  #
  # @param [Integer] index
  # @param [Hash]    req_params
  # @param [Hash]    user_params
  #
  # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#get_previous_and_next_documents_for_search
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#get_previous_and_next_documents_for_search
  #
  def get_previous_and_next_documents_for_search(index, req_params, user_params = nil)
    search_service.get_previous_and_next_documents_for_search(
      index,
      req_params,
      user_params
    )
  end

  # get_opensearch_response
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
  # @return [Array<(String, Array)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#get_opensearch_response
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#get_opensearch_response
  #
  def get_opensearch_response(field = nil, req_params = nil, eds_params = nil)
    search_service.get_opensearch_response(
      field,
      (req_params || params),
      eds_params
    )
  end

  # ===========================================================================
  # :section: Blacklight::SearchHelperExt overrides
  # ===========================================================================

  private

  # Retrieve a set of documents by id.
  #
  # @param [Array] ids
  # @param [Hash]  req_params
  # @param [Hash]  eds_params
  #
  # @return [Array<(Blacklight::Solr::Response, Array<EdsDocument>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#fetch_many
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#fetch_many
  #
  def fetch_many(ids, req_params = nil, eds_params = nil)
    req_params ||= params
    search_service.fetch_many(ids, req_params, eds_params)
  end

  # fetch_one
  #
  # @param [?]    id
  # @param [Hash] eds_params
  #
  # @return [Array<(Blacklight::Solr::Response, EdsDocument)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelperExt#fetch_one
  #
  # Compare with:
  # @see Blacklight::Eds::SearchService#fetch_one
  #
  def fetch_one(id, eds_params = nil)
    search_service.fetch_one(id, eds_params)
  end

end

__loading_end(__FILE__)
