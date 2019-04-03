# app/models/ils_checkouts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/checkout'

# IlsCheckouts
#
# @attr [Array<Ils::Checkout>] checkouts
#
class IlsCheckouts < Ils::Message

  schema do

    has_many :checkouts, wrap: true

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [Symbol] :format
  #
  # This method overrides:
  # @see Ils::Record::Base#initialize
  #
  def initialize(data, **opt)
    super
    self.checkouts = [] if error?
  end

end

__loading_end(__FILE__)
