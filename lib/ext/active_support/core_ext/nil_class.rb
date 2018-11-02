# lib/ext/active_support/core_ext/nil_class.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class NilClass

  # This allows prevents values that might be *nil* from causing a problem in
  # ERB files.
  #
  # @return [nil]
  #
  def html_safe
    nil
  end

end

__loading_end(__FILE__)
