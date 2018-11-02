# app/controllers/concerns/config/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_solr'

module Config

  # Config::Catalog
  #
  class Catalog

    include ::Config::Common
    extend  ::Config::Common
    include ::Config::Base

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Create a configuration object to associate with a controller.
    #
    # @param [Blacklight::Controller] controller
    #
    # @return [::Config::Base]
    #
    def self.build(controller)
      if Blacklight.connection_config[:url].include?(PRODUCTION_SUBNET)
        ::Config::Solr.new(controller)
      else
        require_relative '_solr_fake'
        ::Config::SolrFake.new(controller)
      end.deep_copy(self).tap do |config|
        remove_facets!(config, Solr::VIDEO_TYPES, Solr::MUSIC_TYPES)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # If config/blacklight.yml indicates that the Solr server path includes
    # "lib.virginia.edu" then the real configuration will be used.  Otherwise,
    # the "fake" (local Solr) configuration will be used.
    #
    # @param [Blacklight::Controller, nil] controller
    #
    # @see Config::Solr#instance
    # @see Config::SolrFake#instance
    #
    def initialize(controller = nil)
      controller ||= CatalogController
      config_base  = self.class.build(controller)
      register(config_base)
    end

  end

end

__loading_end(__FILE__)
