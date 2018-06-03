# app/controllers/concerns/config/video.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'catalog'

module Config

  # Default Blacklight Lens for controllers based on this configuration.
  VIDEO_LENS = :video

  VIDEO_CONFIG =
    Config::Catalog.new.deep_copy.tap do |config|

      include Config::Common
      extend  Config::Common

      # Specify the lens key for this configuration.
      config.lens_key = VIDEO_LENS

      # === Facet fields ===

      config.add_facet_field :video_genre_facet

      # === Index (results page) metadata fields ===

      config.add_index_field :video_genre_facet

      # === Item details (show page) metadata fields ===

      config.add_show_field :recordings_and_scores_facet

      # === Search fields ===

      # Hide selected catalog lens search fields.
      config.search_fields.each_pair do |key, field|
        next unless %w(journal issn isbn).include?(key)
        field.include_in_advanced_search = false
      end

      # === Localization ===
      # Get field labels from I18n, including labels specific to this lens.

      finalize_configuration(config)

    end

  # Config::Video
  #
  class Video

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
      super(VIDEO_CONFIG)
    end

  end

  # Assign class lens key.
  Video.key = VIDEO_CONFIG.lens_key

  # Sanity check.
  Blacklight::Lens.validate_key(Video)

end

__loading_end(__FILE__)
