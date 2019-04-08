# app/models/concerns/ils/item_methods.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/common'

# Ils::ItemMethods
#
module Ils::ItemMethods

  include Ils::Common
  extend  Ils::Common

  # An item is a "journal" if its item_type matches one of these.
  #
  # @type [Array<String>]
  #
  JOURNAL_ITEM_TYPES = %w(
    bd-jrnl-nc
    bound-jrnl
    cur-per
    cur-per-nc
    document
  ).freeze

  # ===========================================================================
  # :section: Ils::ItemType "mixins"
  # ===========================================================================

  public

  # A label for the item type that may take up less room than the full name.
  #
  # @return [String]
  #
  # == Implementation Notes
  # For consistency with Ils::LibraryMethods#label.
  #
  def label
    code.to_s.capitalize
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Indicate whether the code is for a periodical or journal.
  #
  # @param [String] code
  #
  # @see #JOURNAL_ITEM_TYPES
  #
  def journal?(code)
    JOURNAL_ITEM_TYPES.include?(code)
  end

end

__loading_end(__FILE__)
