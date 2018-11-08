# app/controllers/concerns/config/articles.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '_eds'

# Configuration for the Articles lens.
#
class Config::Articles < Config::Base

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
  # @see Config::Eds#initialize
  #
  def self.build(controller)
    ::Config::Eds.new(controller)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Blacklight::Controller, nil] controller
  #
  # @see self#build
  #
  # This method overrides:
  # @see Config::Base#initialize
  #
  def initialize(controller = nil)
    controller ||= ArticlesController
    config_base  = self.class.build(controller)
    super(config_base)
  end

end

__loading_end(__FILE__)
