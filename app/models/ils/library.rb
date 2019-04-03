# app/models/ils/library.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/library_methods'

# Ils::Library
#
# @attr [Integer] id
# @attr [String]  code
#
# @attr [String]  name
# @attr [Boolean] deliverable
# @attr [Boolean] holdable
# @attr [Boolean] remote
#
# @see Ils::LibraryMethods
#
class Ils::Library < Ils::Record::Base

  schema do

    attribute :id,          Integer
    attribute :code,        String

    has_one   :name,        String
    has_one   :deliverable, Boolean
    has_one   :holdable,    Boolean
    has_one   :remote,      Boolean

  end

  include Ils::LibraryMethods

end

__loading_end(__FILE__)
