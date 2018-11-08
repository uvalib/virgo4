# app/controllers/concerns/config/video.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_solr'

# Configuration for the Video lens.
#
class Config::Video < Config::Base

  NON_VIDEO_TYPES = Config::Solr::CATALOG_TYPES + Config::Solr::MUSIC_TYPES

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
    ::Config::Solr.new(controller).deep_copy(self).tap do |config|

      # Specify the lens key for this configuration.
      config.lens_key = :video

      # === Facet fields ===

      remove_facets!(config, NON_VIDEO_TYPES)

      # === Index metadata fields ===

      # TODO: ???

      # === Show page (item details) metadata fields ===

      # TODO: ???

      # === Search fields ===

      # Hide selected catalog lens search fields.
      config.search_fields.each_pair do |key, field|
        next unless %w(journal issn isbn).include?(key)
        field.include_in_advanced_search = false
      end

      # === Sort fields ===

      # TODO: ???

      # === Finalize ===

      finalize_configuration!(config)

    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Create a configuration object to associate with a controller.
  #
  # @param [Blacklight::Controller, nil] controller
  #
  # @see self#build
  #
  # This method overrides:
  # @see Config::Base#initialize
  #
  def initialize(controller = nil)
    controller ||= VideoController
    config_base  = self.class.build(controller)
    super(config_base)
  end

end

__loading_end(__FILE__)
