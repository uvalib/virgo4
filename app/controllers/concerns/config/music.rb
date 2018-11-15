# app/controllers/concerns/config/music.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_solr'

# Configuration for the Music lens.
#
class Config::Music < Config::Base

  NON_MUSIC_TYPES = Config::Solr::CATALOG_TYPES + Config::Solr::VIDEO_TYPES

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
      config.lens_key = :music

      # === Facet fields ===

      remove_facets!(config, NON_MUSIC_TYPES)

      # === Index metadata fields ===

      #config.add_index_field 'recording_format_f'     # TODO: not in index

      # === Show page (item details) metadata fields ===

      #config.add_show_field 'instrument_f'
      #config.add_show_field 'composition_era_f'
      #config.add_show_field 'recordings_and_scores_f' # TODO: not in index

      # === Search fields ===

      # Hide selected catalog lens search fields.
      config.search_fields.each_pair do |key, field|
        next unless %w(journal issn).include?(key)
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
    values += %i(music_library)
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
    controller ||= MusicController
    config_base  = self.class.build(controller)
    super(config_base)
  end

end

__loading_end(__FILE__)
