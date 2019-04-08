# app/models/ils/holdability.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Ils::Holdability
#
# @attr [Integer] message_code
# @attr [String]  name
# @attr [String]  value
#
# @attr [String]  message
#
class Ils::Holdability < Ils::Record::Base

  schema do

    attribute :message_code, Integer
    attribute :name,         String
    attribute :value,        String

    has_one   :message,      String

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # holdable?
  #
  def holdable?
    %w(yes maybe).include?(value.to_s.downcase)
  end

end

__loading_end(__FILE__)
