# app/models/ils/violation.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Ils::Violation
#
# @attr [String] code
# @attr [String] message
#
class Ils::Violation < Ils::Record::Base

  schema do

    has_one :code,    String
    has_one :message, String

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Show the contents of self for logging and/or display to the user.
  #
  # @return [String]
  #
  def to_s
    [].tap { |parts|
      parts << message.inspect     if message.present?
      parts << "[#{code.inspect}]" if code.present?
    }.join(' ')
  end

end

__loading_end(__FILE__)
