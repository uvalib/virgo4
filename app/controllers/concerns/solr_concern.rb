# app/controllers/concerns/solr_concern.rb
#
# encoding:              utf-8
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

module SolrConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'SolrConcern')

    include RescueConcern
    include LensConcern

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :default_catalog_controller if defined?(helper_method)

    # =========================================================================
    # :section: Controller exception handling
    # =========================================================================

    public

    rescue_from *[
      RSolr::Error::ConnectionRefused,
      Blacklight::Exceptions::ECONNREFUSED
    ], with: :handle_solr_connect_error

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The default controller for searches.
    #
    # @return [Class]
    #
    def default_catalog_controller
      CatalogController
    end

    # The default controller for searches.
    #
    # @return [Class]
    #
    def self.default_catalog_controller
      CatalogController
    end

  end

  # ===========================================================================
  # :section: Exception handlers
  # ===========================================================================

  protected

  # This method is executed when there is a problem communicating with the Solr
  # indexing service.
  #
  # @param [Exception] exception
  #
  def handle_solr_connect_error(exception)
    handle_connect_error(exception, 'blacklight.search.errors.connect.solr')
  end

end

__loading_end(__FILE__)
