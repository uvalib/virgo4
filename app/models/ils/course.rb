# app/models/ils/course.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/reserve'

# Ils::Course
#
# @attr [String]  key
#
# @attr [String]  code
# @attr [String]  name
# @attr [Integer] number_of_reserves
# @attr [Integer] number_of_students
# @attr [Integer] terms_offered
#
# @attr [Array<Ils::Reserve>] reserves
#
class Ils::Course < Ils::Record::Base

  schema do

    attribute :key,                 String

    has_one   :code,                String
    has_one   :name,                String
    has_one   :number_of_reserves,  Integer
    has_one   :number_of_students,  Integer
    has_one   :terms_offered,       Integer

    has_many  :reserves

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # sorted_reserves
  #
  # @return [Array<Reserve>]
  #
  def sorted_reserves
    reserves.sort_by { |a| a.catalog_item.title }
  end

end

__loading_end(__FILE__)
