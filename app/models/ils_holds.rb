# app/models/ils_holds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/hold'

# IlsHolds
#
# @attr [Array<Ils::Hold>] holds
#
class IlsHolds < Ils::Message

  schema do

    has_many :holds, wrap: true

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
    self.holds = [] if error?
  end

end

__loading_end(__FILE__)
