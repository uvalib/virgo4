# app/helpers/icon_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens'

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::IconHelperBehavior
#
module IconHelper

  include Blacklight::IconHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[IconHelper]')
  end

  # TODO: ???

end

__loading_end(__FILE__)
