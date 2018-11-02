# app/services/blacklight/solr/search_service.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight'
require 'blacklight/solr'
require_relative '../lens/search_service'

module Blacklight::Solr

  # Blacklight::Solr::SearchService
  #
  # Returns search results from a Solr index service.
  #
  # @see Blacklight::Lens::SearchService
  #
  class SearchService < Blacklight::Lens::SearchService

    # TODO: ???

  end

end

__loading_end(__FILE__)
