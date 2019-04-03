# app/models/ils/holding.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/copy'
require 'ils/home_library'

# Ils::Holding
#
# @attr [Integer] call_sequence
# @attr [String]  call_number
# @attr [Boolean] holdable
# @attr [Boolean] shadowed
#
# @attr [String]       shelving_key
# @attr [Ils::Library] library
#
# @attr [Array<Ils::Copy>] copies
#
class Ils::Holding < Ils::Record::Base

  schema do

    attribute :call_sequence, Integer
    attribute :call_number,   String
    attribute :holdable,      Boolean
    attribute :shadowed,      Boolean

    has_one   :shelving_key,  String
    has_one   :library,       Ils::HomeLibrary

    has_many  :copies

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
  # @option options [SolrDocument] :doc
  #
  def initialize(data = nil, **opt)
    super
    if error?
      self.library = Ils::HomeLibrary.new(nil, error: exception)
      self.copies  = []
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # shadowed?
  #
  def shadowed?
    shadowed.present?
  end

  # holdable?
  #
  # === Usage Notes
  # Items in the Deans Office are marked as non-circulating but we want them
  # to be requestable via Sirsi.
  #
  def holdable?
    holdable.present? || deans_office?
  end

  # leoable?
  #
  def leoable?
    library.present? && library.leoable?
  end

  # special_collections?
  #
  def special_collections?
    library.present? && library.is_special_collections?
  end

  # ivy_annex?
  #
  def ivy_annex?
    if library&.is_ivy?
      copies.any?(&:ivy_annex?)
    else
      copies.any?(&:by_request?)
    end
  end

  # ivy_stacks?
  #
  def ivy_stacks?
    if library&.is_ivy?
      copies.any? { |copy| copy.exists? && !copy.ivy_annex? }
    else
      copies.any?(&:ivy_stacks?)
    end
  end

  # deans_office?
  #
  def deans_office?
    copies.any?(&:deans_office?)
  end

  # Indicate whether the item is a periodical or journal.  (For ordered lists
  # of items, these are sorted in reverse order.)
  #
  # @see Ils::Copy#journal?
  #
  def journal?
    copies.any?(&:journal?)
  end

  # The number of available copies for this holding.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  def available_copies
    copies.count(&:available?)
  end

  # The number of reserve copies for this holding.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  def reserve_copies
    copies.count(&:on_reserve?)
  end

  # The number of circulating copies for this holding.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  def circulating_copies
    copies.count(&:circulates?)
  end

  # The number of Special Collections copies for this holding.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  def special_collections_copies
    special_collections? ? existing_copies : 0
  end

  # The number of copies for this holding that are accounted for.
  #
  # @return [Integer]
  #
  def existing_copies
    copies.count(&:exists?)
  end

  # The number of copies for this holding can appear in holdings lists.
  #
  # @return [Integer]
  #
  def visible_copies
    copies.count(&:visible?)
  end

  # Indicate whether the holding contains no items.
  #
  def empty?
    copies.empty?
  end

  alias_method :blank?, :empty?

end

__loading_end(__FILE__)
