# app/controllers/concerns/blacklight/base_ext.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# An extension to Blacklight::Base.
#
# Compare with:
# @see Blacklight::Base
#
module Blacklight::BaseExt

  extend ActiveSupport::Concern

  include Blacklight::Base

  include Blacklight::ConfigurableExt
  include Blacklight::SearchHelperExt
  include Blacklight::SearchContextExt

  # Code to be added to the controller class including this module.
  included do |base|

    __included(base, 'Blacklight::BaseExt')

    include RescueConcern
    include LensConcern

  end

end

__loading_end(__FILE__)
