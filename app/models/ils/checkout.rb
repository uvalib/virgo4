# app/models/ils/checkout.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/catalog_item'
require 'ils/renewability'

# Ils::Checkout
#
# @attr [String]  key
# @attr [Integer] status
# @attr [Boolean] overdue
# @attr [Integer] circulation_rule
# @attr [Date]    date_charged
# @attr [Date]    date_due
# @attr [Date]    date_renewed
# @attr [Date]    date_recalled
# @attr [Integer] number_overdue_notices
# @attr [Integer] number_recall_notices
# @attr [Integer] number_renewals
#
# @attr [Ils::CatalogItem]  catalog_item
# @attr [Ils::Renewability] renewability
#
class Ils::Checkout < Ils::Record::Base

  schema do

    has_one :key,                     String
    has_one :status,                  Integer
    has_one :overdue,                 Boolean, as: 'isOverdue'
    has_one :circulation_rule,        Integer
    has_one :date_charged,            Date
    has_one :date_due,                Date
    has_one :date_renewed,            Date
    has_one :date_recalled,           Date
    has_one :number_overdue_notices,  Integer
    has_one :number_recall_notices,   Integer
    has_one :number_renewals,         Integer

    has_one :catalog_item
    has_one :renewability, as: 'canRenew'

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # renewable?
  #
  def renewable?
    renewability&.value == 'yes'
  end

  # overdue?
  #
  def overdue?
    overdue.present?
  end

  # recalled?
  #
  def recalled?
    date_recalled_f != 'Never'
  end

  # date_charged_f
  #
  # @return [String]
  #
  def date_charged_f
    date_format(date_charged)
  end

  # date_due_f
  #
  # @return [String]
  #
  def date_due_f
    date_format(date_due)
  end

  # date_recalled_f
  #
  # @return [String]
  #
  def date_recalled_f
    date_format(date_recalled)
  end

  # date_renewed_f
  #
  # @return [String]
  #
  def date_renewed_f
    date_format(date_renewed)
  end

end

__loading_end(__FILE__)
