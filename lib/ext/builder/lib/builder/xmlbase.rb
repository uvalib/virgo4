# lib/ext/builder/lib/builder/xmlbase.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'builder/xmlbase'

# Builder::XmlBaseExt
#
# @see Builder::XmlBase
#
module Builder::XmlBaseExt

  # Prefix *text* with spaces to indent to the current indentation level.
  #
  # @param [String]       text
  # @param [Integer, nil] lvl         Default: @level.
  #
  def indented!(text, lvl = @level)
    spaces = ' ' * (lvl * @indent)
    self << text.gsub(/^/, spaces)
  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override Builder::XmlBase => Builder::XmlBaseExt

__loading_end(__FILE__)
