# app/controllers/concerns/blacklight/eds/search_context_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::SearchContextExt for controllers that work with
# articles (EdsDocument).
#
# @see Blacklight::SearchContextExt
# @see Blacklight::SearchContext
#
module Blacklight::Eds::SearchContextEds

  extend ActiveSupport::Concern

  include Blacklight::SearchContextExt
  include Blacklight::Eds::SearchHelperEds

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::Eds::SearchContextEds')

  end

end

__loading_end(__FILE__)
