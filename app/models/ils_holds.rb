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

  delegate_missing_to :holds

end

__loading_end(__FILE__)
