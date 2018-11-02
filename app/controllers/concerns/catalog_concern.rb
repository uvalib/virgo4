# app/controllers/concerns/catalog_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/catalog'

# CatalogConcern
#
module CatalogConcern

  extend ActiveSupport::Concern

  include Blacklight::Solr::Controller
  include Blacklight::Solr::Catalog
  include Blacklight::Marc::Catalog
  include SolrConcern

  included do |base|
    __included(base, 'CatalogConcern')
  end

end

__loading_end(__FILE__)
