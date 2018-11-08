# app/controllers/concerns/blacklight/solr/controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/solr'

# An extension of Blacklight::Controller supporting Blacklight Lens for
# controllers that work with index items (SolrDocument).
#
# Compare with:
# @see Blacklight::Controller
#
module Blacklight::Solr::Controller

  extend ActiveSupport::Concern

  include Blacklight::Lens::Controller

  included do |base|

    __included(base, 'Blacklight::Solr::Controller')

    # =========================================================================
    # :section: Class attributes
    # =========================================================================

    self.search_state_class   = Blacklight::Solr::SearchState
    self.search_service_class = Blacklight::Solr::SearchService

  end

end

__loading_end(__FILE__)
