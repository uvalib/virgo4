# app/controllers/concerns/blacklight/eds/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::Catalog for controllers that work with
# articles (EdsDocument).
#
# @see Blacklight::Catalog
#
module Blacklight::Eds::Catalog

  extend ActiveSupport::Concern

  include Blacklight::Lens::Catalog

  included do |base|
    __included(base, 'Blacklight::Eds::Catalog')
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /articles/:id/fulltext
  #
  def fulltext
    fulltext_url = search_service.fetch_fulltext(params[:id], params[:type])
    redirect_to fulltext_url, status: 303 if fulltext_url
  end

  # =========================================================================
  # :section: Blacklight::Catalog overrides
  # =========================================================================

  protected

  # suggestions_service
  #
  # @return [Blacklight::Eds::Suggest::Response]
  #
  # This method overrides:
  # @see Blacklight::Catalog#suggestions_service
  #
  def suggestions_service
    req_params = params.merge(session.to_hash)
    repository = search_service.repository
    Blacklight::Eds::SuggestSearch.new(req_params, repository).suggestions
  end

end

__loading_end(__FILE__)
