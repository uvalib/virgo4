# app/models/ils/catalog_item.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/holdability'
require 'ils/holding'

# Ils::CatalogItem
#
# @attr [String]  key
#
# @attr [Integer] status
#
# @attr [Ils::Holdability]    holdability
#
# @attr [Array<Ils::Holding>] holdings
#
class Ils::CatalogItem < Ils::Record::Base

  schema do

    attribute :key,         String

    has_one   :status,      Integer

    has_one   :holdability, as: 'canHold'

    has_many  :holdings

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # The Solr document assigned within the initializer for Availability.
  #
  # @return [SolrDocument]
  #
  attr_accessor :document

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         opt
  #
  # @option options [SolrDocument] :doc
  #
  def initialize(data = nil, **opt)
    @document = opt[:doc]
    super(data, opt.except(:doc))
    if error?
      self.holdability = Ils::Holdability.new(nil, error: exception)
      self.holdings    = []
    end
  end

  # ===========================================================================
  # :section: Document-related methods
  # ===========================================================================

  public

  # Assignment of Solr document performed within the initializer for
  # Availability.
  #
  # To be called directly after creating a instance by parsing XML.
  #
  # @param [SolrDocument] doc
  #
  # @return [SolrDocument]
  #
  def document=(doc)
    raise '@document may only be assigned once' if @document
    @document = doc
  end

  # The title of the requested catalog entry.
  #
  # @return [String]                '???' indicates either that there was no
  #                                   Solr document for the catalog entry or
  #                                   that the entry had no title.
  #
  # @see Blacklight::Document#export_title
  #
  def title
    document&.export_title&.presence || '???'
  end

  # The first author of the requested catalog entry.
  #
  # @return [String]                '???' indicates that there was no Solr
  #                                   document for the catalog entry; if the
  #                                   entry simply has no authors given then
  #                                   '' is returned.
  #
  # @see Blacklight::Document#export_authors
  #
  def authors
    document&.export_authors&.presence || '???'
  end

  # ===========================================================================
  # :section: Holding-related methods
  # ===========================================================================

  public

  # The number of available copies of this catalog entry.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  # @see Ils::Holding#available_copies
  #
  def available_copies
    holdings.sum(&:available_copies)
  end

  # The number of copies of this catalog entry on course reserve.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  # @see Ils::Holding#reserve_copies
  #
  def reserve_copies
    holdings.sum(&:reserve_copies)
  end

  # The number of copies of this catalog entry that could be potentially
  # checked out.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  # @see Ils::Holding#circulating_copies
  #
  def circulating_copies
    holdings.sum(&:circulating_copies)
  end

  # The number of copies of this catalog entry that are in Special Collections.
  #
  # @return [Integer]               Range: from 0 to self#existing_copies.
  #
  # @see Ils::Holding#special_collections_copies
  #
  def special_collections_copies
    holdings.sum(&:special_collections_copies)
  end

  # The number of copies of this catalog entry that are accounted for.
  #
  # @return [Integer]
  #
  # @see Ils::Holding#existing_copies
  #
  def existing_copies
    holdings.sum(&:existing_copies)
  end

  # The number of copies of this catalog entry can appear in holdings lists.
  #
  # @return [Integer]
  #
  # @see Ils::Holding#visible_copies
  #
  def visible_copies
    holdings.sum(&:visible_copies)
  end

  # ===========================================================================
  # :section: Holdability-related methods
  # ===========================================================================

  public

  # holdable?
  #
  # === Usage Notes
  # Items in the Deans Office are marked as non-circulating but we want them
  # to be requestable via Sirsi.
  #
  def holdable?
    holdability.holdable? || holdings.any?(&:deans_office?)
  end

  # holdability_error
  #
  # @return [String]
  #
  def holdability_error
    holdability.message
  end

  # has_holdable_holding?
  #
  # @param [String] call_number
  #
  def has_holdable_holding?(call_number)
    call_number = comparable(call_number)
    holdable_call_numbers.any? { |number| call_number == comparable(number) }
  end

  # holdable_call_numbers
  #
  # @param [Boolean, Symbol, nil] reverse   Indicate sort preference:
  #                                           *nil*   - no sort (default)
  #                                           *true*  - sort reverse
  #                                           *false* - sort forward
  #                                           :auto   - auto order selection
  #
  # @return [Array<String>]
  #
  def holdable_call_numbers(reverse = nil)
    holdings.select(&:holdable?).uniq(&:shelving_key).tap { |result|
      unless reverse.nil?
        reverse = result.any?(&:journal?) if reverse == :auto
        result.sort_by!(&:shelving_key)
        result.reverse! if reverse
      end
    }.map(&:call_number)
  end

end

__loading_end(__FILE__)
