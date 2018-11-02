# app/helpers/hash_as_hidden_fields_helper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modifies Blacklight module definitions with local behaviors.
#
# @see Blacklight::HashAsHiddenFieldsHelperBehavior
#
module HashAsHiddenFieldsHelper

  include Blacklight::HashAsHiddenFieldsHelperBehavior
  include LensHelper

  def self.included(base)
    __included(base, '[HashAsHiddenFieldsHelper]')
  end

  # TODO: ???

end

__loading_end(__FILE__)
