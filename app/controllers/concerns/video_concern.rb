# app/controllers/concerns/video_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'config/video'

# CatalogConcern
#
module VideoConcern

  extend ActiveSupport::Concern

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'VideoConcern')

    include SolrConcern

    if base == VideoController
      self.blacklight_config = Config::Video.new.blacklight_config
    else
      copy_blacklight_config_from(VideoController)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # The default controller for searches.
    #
    # @return [Class]
    #
    def default_catalog_controller
      VideoController
    end

    # The default controller for searches.
    #
    # @return [Class]
    #
    def self.default_catalog_controller
      VideoController
    end

  end

end

__loading_end(__FILE__)
