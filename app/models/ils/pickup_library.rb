# app/models/ils/pickup_library.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Ils::PickupLibrary
#
# @attr [Integer] id
# @attr [String]  code
#
# @attr [String]  name
#
class Ils::PickupLibrary < Ils::Record::Base

  schema do

    attribute :id,   Integer
    attribute :code, String

    has_one   :name, String

  end

end

__loading_end(__FILE__)
