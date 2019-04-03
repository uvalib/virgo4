# app/models/ils/reserve.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/catalog_item'

# Ils::Reserve
#
# @attr [String]  key
#
# @attr [String]  active
# @attr [String]  status
# @attr [Integer] number_of_reserves
# @attr [Boolean] keep_copies_at_desk
# @attr [Boolean] automatically_select_copies
#
# @attr [Ils::CatalogItem] catalog_item
#
class Ils::Reserve < Ils::Record::Base

  schema do

    attribute :key,                         String

    has_one   :active,                      String
    has_one   :status,                      String
    has_one   :number_of_reserves,          Integer
    has_one   :keep_copies_at_desk,         Boolean
    has_one   :automatically_select_copies, Boolean

    has_one   :catalog_item

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
      self.catalog_item = Ils::CatalogItem.new(nil, error: exception)
    end
  end

end

__loading_end(__FILE__)
