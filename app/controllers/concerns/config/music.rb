# app/controllers/concerns/config/music.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'catalog'

module Config

  # Default Blacklight Lens for controllers based on this configuration.
  MUSIC_LENS = :music

  MUSIC_CONFIG =
    Config::Catalog.new.deep_copy.tap do |config|

      include Config::Common
      extend  Config::Common

      # Specify the lens key for this configuration.
      config.lens_key = MUSIC_LENS

      # === Facet fields ===

      config.add_facet_field :recording_format_facet
      config.add_facet_field :instrument_facet
      config.add_facet_field :music_composition_era_facet
      config.add_facet_field :recordings_and_scores_facet

      # === Index (results page) metadata fields ===

      config.add_index_field :recording_format_facet

      # === Item details (show page) metadata fields ===

      config.add_show_field :instrument_facet
      config.add_show_field :music_composition_era_facet
      config.add_show_field :recordings_and_scores_facet

      # === Search fields ===

      # Hide selected catalog lens search fields.
      config.search_fields.each_pair do |key, field|
        next unless %w(journal issn).include?(key)
        field.include_in_advanced_search = false
      end

      # === Localization ===

      finalize_configuration(config)

    end

  # Config::Music
  #
  class Music

    include Config::Base

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a self instance.
    #
    # @see Config::Catalog#instance
    #
    def initialize
      super(MUSIC_CONFIG)
    end

  end

  # Assign class lens key.
  Music.key = MUSIC_CONFIG.lens_key

  # Sanity check.
  Blacklight::Lens.validate_key(Music)

end

__loading_end(__FILE__)
