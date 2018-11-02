# app/controllers/concerns/config/articles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_base'
require_relative '_eds'

module Config

  # Config::Articles
  #
  class Articles

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
      ::Config::Eds.new(controller)
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Initialize a new instance.
    #
    # @param [Blacklight::Controller, nil] controller
    #
    # @see Config::Eds#instance
    #
    def initialize(controller = nil)
      controller ||= ArticlesController
      config_base  = self.class.build(controller)
      register(config_base)
    end

  end

end

__loading_end(__FILE__)
