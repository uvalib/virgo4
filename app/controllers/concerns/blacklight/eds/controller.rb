# app/controllers/concerns/blacklight/eds/controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::Controller supporting Blacklight Lens for
# controllers that work with articles (EdsDocument).
#
# Compare with:
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
