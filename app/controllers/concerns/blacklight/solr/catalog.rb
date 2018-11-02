# app/controllers/concerns/blacklight/solr/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr'

module Blacklight::Solr::Catalog

  extend ActiveSupport::Concern

  include Blacklight::Lens::Catalog

  included do |base|
    __included(base, 'Blacklight::Solr::Catalog')
  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  protected

  # suggestions_service
  #
  # @return [Blacklight::Suggest::Response]
  #
  # This method overrides:
  # @see Blacklight::Catalog#suggestions_service
  #
  def suggestions_service
    repository = search_service.repository
    Blacklight::Solr::SuggestSearch.new(params, repository).suggestions
  end

end

__loading_end(__FILE__)
