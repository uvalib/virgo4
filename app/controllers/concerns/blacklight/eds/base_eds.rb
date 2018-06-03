# app/controllers/concerns/blacklight/eds/base_eds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/eds'

# An extension of Blacklight::BaseExt for controllers that work with articles
# (EdsDocument).
#
# @see Blacklight::BaseExt
# @see Blacklight::Base
#
module Blacklight::Eds::BaseEds

  extend ActiveSupport::Concern

  include Blacklight::BaseExt

  include Blacklight::Eds::SearchHelperEds
  include Blacklight::Eds::SearchContextEds

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::Eds::BaseEds')

    include LensConcern

  end

end

__loading_end(__FILE__)
