# app/models/ils/renewability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Ils::Renewability
#
# @attr [String]  code
# @attr [String]  value
#
# @attr [String]  message
#
class Ils::Renewability < Ils::Record::Base

  schema do

    attribute :code,    String
    attribute :value,   String

    has_one   :message, String

  end

end

__loading_end(__FILE__)
