# app/controllers/concerns/config/video.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_solr'

# Configuration for the Video lens.
#
class Config::Video < Config::Base

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

      remove_facets!(config, Config::Solr::CATALOG_TYPES)
      remove_facets!(config, Config::Solr::MUSIC_TYPES)

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

      # === Search parameters ===

      search_builder_processors!(config)

      # === Finalize ===

      finalize_configuration!(config)

    end
  end

  # Set the filter query parameters for the lens.
  #
  # @param [Blacklight::Configuration] config
  # @param [Array<Symbol>]             values
  #
  # @return [void]
  #
  # @see Config::Solr#search_builder_processors!
  # @see SearchBuilderSolr#
  #
  def self.search_builder_processors!(config, *values)
    values += %i(video_format)
    super(config, values)
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
