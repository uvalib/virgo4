# app/controllers/concerns/blacklight/eds/controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# Filters added to this controller apply to all controllers in the
# hosting application as this module is mixed-in to the application controller
# in the hosting app on installation.
#
# @see Blacklight::Controller
#
module Blacklight::Eds::Controller

  extend ActiveSupport::Concern

  include Blacklight::Lens::Controller

  included do |base|

    __included(base, 'Blacklight::Eds::Controller')

    # =========================================================================
    # :section: Class attributes
    # =========================================================================

    self.search_state_class   = Blacklight::Eds::SearchState
    self.search_service_class = Blacklight::Eds::SearchService

  end

end

__loading_end(__FILE__)
