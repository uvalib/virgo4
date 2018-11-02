# app/controllers/concerns/config/music.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative 'catalog'

module Config

  # Config::Music
  #
  class Music

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
      ::Config::Solr.new(controller).deep_copy(self).tap do |config|

        config.klass = controller.is_a?(Class) ? controller : controller.class

        # Specify the lens key for this configuration.
        config.lens_key = :music

        # === Facet fields ===

        remove_facets!(config, Solr::CATALOG_TYPES, Solr::VIDEO_TYPES)

        # === Index (results page) metadata fields ===

        #config.add_index_field 'recording_format_f'     # TODO: not in index

        # === Item details (show page) metadata fields ===

        #config.add_show_field 'instrument_f'
        #config.add_show_field 'composition_era_f'
        #config.add_show_field 'recordings_and_scores_f' # TODO: not in index

        # === Search fields ===

        # Hide selected catalog lens search fields.
        config.search_fields.each_pair do |key, field|
          next unless %w(journal issn).include?(key)
          field.include_in_advanced_search = false
        end

        # === Localization ===

        finalize_configuration!(config)

      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Blacklight::Controller, nil] controller
    #
    # @see Config::Catalog#instance
    #
    def initialize(controller = nil)
      controller ||= MusicController
      config_base  = self.class.build(controller)
      register(config_base)
    end

  end

end

__loading_end(__FILE__)
