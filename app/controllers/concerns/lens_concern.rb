# app/controllers/concerns/lens_concern.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Support for the "lens" concept.
#
# @see LensHelper
#
module LensConcern

  extend ActiveSupport::Concern

  include LensHelper

  included do |base|

    __included(base, 'LensConcern')

    # =========================================================================
    # :section: Helpers
    # =========================================================================

    helper_method :lens_key if respond_to?(:helper_method)

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
