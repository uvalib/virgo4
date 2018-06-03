# app/controllers/concerns/lens_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Support for the "lens" concept.
#
# @see LensHelper
#
module LensConcern

  extend ActiveSupport::Concern

  include LensHelper

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'LensConcern')

    include Blacklight::ConfigurableExt

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :lens_key if defined?(helper_method)

    # =========================================================================
    # :section: Controller methods
    # =========================================================================

    public

    # The (potential) lens key for the current controller.
    #
    # @return [Symbol, nil]
    #
    def lens_key
      Blacklight::Lens.key_for(controller_name, false)
    end

    # =========================================================================
    # :section: Controller class methods
    # =========================================================================

    public

    # The (potential) lens key for the current controller class.
    #
    # @return [Symbol, nil]
    #
    def self.lens_key
      Blacklight::Lens.key_for(controller_name, false)
    end

  end

end

__loading_end(__FILE__)
