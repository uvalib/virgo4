# app/models/ils/current_location.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/location_methods'

# Ils::CurrentLocation
#
# @attr [Integer] id
# @attr [String]  code
#
# @attr [String]  name
#
# @see Ils::LocationMethods
#
class Ils::CurrentLocation < Ils::Record::Base

  schema do

    attribute :id,   Integer
    attribute :code, String

    has_one   :name, String

  end

  include Ils::LocationMethods

end

__loading_end(__FILE__)
