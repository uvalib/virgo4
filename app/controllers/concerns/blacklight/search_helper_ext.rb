# app/controllers/concerns/blacklight/search_helper_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Replacement for Blacklight::SearchHelper
#
# @see Blacklight::SearchHelper
#
module Blacklight::SearchHelperExt

  extend ActiveSupport::Concern

  include Blacklight::SearchHelper
  include LensHelper

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::SearchHelperExt')

    include LensConcern

  end

  # ===========================================================================
  # :section: Blacklight::SearchHelper overrides
  # ===========================================================================

  private

  # Retrieve a set of documents by id.
  #
  # @param [Array] ids
  # @param [Hash]  user_params
  # @param [Hash]  solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Array<Blacklight::Document>)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch_many
  #
  # Compare with (for articles search):
  # @see Blacklight::Eds::SearchService#fetch_many
  #
  def fetch_many(ids, user_params = nil, solr_params = nil)
    # Get each item from its appropriate repository one-at-a-time rather than
    # as a batch (search) request.  This is for two reasons:
    # 1. Ensure that each failed item is indicated with a *nil* value.
    # 2. To better support cache management.
    response_hash = {}
    response_docs = {}
    Array.wrap(ids).each do |id|
      next if response_hash[id] && response_docs[id]
      response, document = fetch_one(id, solr_params)
      response &&= response['response']
      response &&= response['doc'] || response['docs']
      response_hash[id] = Array.wrap(response).first || document&.to_h
      response_docs[id] = document
    end

    # Manufacture a response from the sets of document hash values.
    response_params = Blacklight::Parameters.sanitize(user_params)
    response = Blacklight::Solr::Response.new({}, response_params)
    response['response'] ||= {}
    response['response']['docs'] = response_hash.values
    return response, response_docs.values
  end

  # Retrieve a single document by id.
  #
  # @param [String] id
  # @param [Hash]   solr_params
  #
  # @return [Array<(Blacklight::Solr::Response, Blacklight::Document)>]
  #
  # This method overrides:
  # @see Blacklight::SearchHelper#fetch_one
  #
  # Compare with (for articles search):
  # @see Blacklight::Eds::SearchService#fetch_one
  #
  def fetch_one(id, solr_params = nil)
    solr_params ||= {}
    response = repository.find(id, solr_params)
    return response, response.documents.first
  end

end

__loading_end(__FILE__)
