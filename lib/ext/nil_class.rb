# lib/ext/nil_class.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading(__FILE__)

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
