# app/controllers/concerns/config/catalog.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_solr'

# Configuration for the Catalog lens.
#
class Config::Catalog < Config::Base

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a configuration object to associate with a controller.
  #
  # @param [Blacklight::Controller] controller
  #
  # @return [::Config::Base]
  #
  # @see Config::Solr#initialize
  #
  def self.build(controller)
    cfg =
      if Blacklight.connection_config[:url].include?(PRODUCTION_SUBNET)
        ::Config::Solr.new(controller)
      else
        require_relative '_solr_fake'
        ::Config::SolrFake.new(controller)
      end
    cfg.tap do |config|
      remove_facets!(config, Config::Solr::VIDEO_TYPES)
      remove_facets!(config, Config::Solr::MUSIC_TYPES)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # If config/blacklight.yml indicates that the Solr server path includes
  # "lib.virginia.edu" then the real configuration will be used.  Otherwise,
  # the "fake" (local Solr) configuration will be used.
  #
  # @param [Blacklight::Controller, nil] controller
  #
  # @see self#build
  #
  # This method overrides:
  # @see Config::Base#initialize
  #
  def initialize(controller = nil)
    controller ||= CatalogController
    config_base  = self.class.build(controller)
    super(config_base)
  end

end

__loading_end(__FILE__)
