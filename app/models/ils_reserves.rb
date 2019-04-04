# app/models/ils_reserves.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/reserve'

# IlsReserves
#
# @attr [Array<Ils::IlsReserve>] reserves
#
class IlsReserves < Ils::Message

  schema do

    has_many :reserves, wrap: true

  end

  delegate_missing_to :reserves

end

__loading_end(__FILE__)
