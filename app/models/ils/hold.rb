# app/models/ils/hold.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/catalog_item'
require 'ils/pickup_library'

# Ils::Hold
#
# @attr [String]  type
# @attr [String]  level
# @attr [Boolean] active
#
# @attr [String]  key
# @attr [Integer] priority
# @attr [Date]    date_placed
# @attr [Date]    date_notified
# @attr [Date]    date_recalled
# @attr [String]  inactive_reason
#
# @attr [Ils::CatalogItem]   catalog_item
# @attr [Ils::PickupLibrary] pickup_library
#
class Ils::Hold < Ils::Record::Base

  schema do

    attribute :type,            String
    attribute :level,           String
    attribute :active,          Boolean

    has_one   :key,             String
    has_one   :priority,        Integer
    has_one   :date_placed,     Date
    has_one   :date_notified,   Date
    has_one   :date_recalled,   Date
    has_one   :inactive_reason, String

    has_one   :catalog_item
    has_one   :pickup_library

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         opt
  #
  def initialize(data = nil, **opt)
    super
    if error?
      self.catalog_item   = Ils::CatalogItem.new(nil, error: exception)
      self.pickup_library = Ils::PickupLibrary.new(nil, error: exception)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # date_placed_f
  #
  # @return [String]
  #
  def date_placed_f
    date_format(date_placed)
  end

  # date_notified_f
  #
  # @return [String]
  #
  def date_notified_f
    date_format(date_notified)
  end

  # date_recalled_f
  #
  # @return [String]
  #
  def date_recalled_f
    date_format(date_recalled)
  end

end

__loading_end(__FILE__)
