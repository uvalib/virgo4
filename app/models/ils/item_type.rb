# app/models/ils/item_type.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/item_methods'

# Ils::ItemType
#
# @attr [Integer] id
# @attr [String]  code
#
# @see Ils::ItemMethods
#
class Ils::ItemType < Ils::Record::Base

  schema do

    attribute :id,   Integer
    attribute :code, String

  end

  include Ils::ItemMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show the item type code.
  #
  # @return [String]
  #
  def to_s
    code.to_s
  end

end

__loading_end(__FILE__)
