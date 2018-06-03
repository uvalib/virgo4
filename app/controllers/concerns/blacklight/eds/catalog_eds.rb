# app/controllers/concerns/blacklight/eds/catalog_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::CatalogExt for controllers that work with
# articles (EdsDocument).
#
# @see Blacklight::CatalogExt
# @see Blacklight::Catalog
#
module Blacklight::Eds::CatalogEds

  extend ActiveSupport::Concern

  include Blacklight::CatalogExt
  include Blacklight::Eds::BaseEds

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::Eds::CatalogEds')

    include EdsConcern

  end

  # ===========================================================================
  # :section: Blacklight::Catalog overrides
  # ===========================================================================

  public

  # == GET /articles
  # Get search results from the EBSCO EDS search service.
  #
  # @see EdsConcern#get_eds_results
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#index
  #
  def index
    super
  end

  # == GET /articles/:id
  # Get a single document from the EBSCO EDS search service.
  #
  # To add responses for formats other than HTML or JSON:
  # @see Blacklight::Document::Export
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#show
  #
  def show
    super
  end

  # == POST /articles/:id/track
  # Updates the search counter (allows the show view to paginate).
  #
  # This method overrides:
  # @see Blacklight::Catalog#track
  #
  def track
    super
  end

  # == GET /articles/facet/:id
  # Displays values and pagination links for a single facet field.
  #
  # @raise [ActionController::RoutingError]
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#facet
  #
  def facet
    super
  end

  # == GET /articles/opensearch
  # Method to serve up XML OpenSearch description and JSON autocomplete
  # response.
  #
  # This method overrides:
  # @see Blacklight::CatalogExt#opensearch
  #
  def opensearch
    super
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # == GET /articles/:id/fulltext
  #
  def fulltext
    fulltext_url = fetch_fulltext(params[:id], params[:type])
    redirect_to fulltext_url, status: 303 if fulltext_url
  end

end

__loading_end(__FILE__)
