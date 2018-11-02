# app/models/blacklight/solr/suggest_search.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr'
require_relative '../lens/suggest_search'

module Blacklight::Solr

  # Blacklight::Solr::SuggestSearch
  #
  class SuggestSearch < Blacklight::Lens::SuggestSearch

    # TODO: ???

  end

end

__loading_end(__FILE__)
