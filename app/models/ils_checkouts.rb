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

  delegate_missing_to :checkouts

end

__loading_end(__FILE__)
