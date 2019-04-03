# app/models/ils_error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/violation'

# IlsError
#
# @attr [Ils::Violation>] violation
#
class IlsError < Ils::Message

  schema do

    has_one :violation, Ils::Violation, as: 'firehoseViolation'

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [Symbol] :format
  #
  # This method overrides:
  # @see Ils::Record::Base#initialize
  #
  def initialize(data, **opt)
    super
    self.violation = Ils::Violation.new(nil, error: exception) if error?
  end

end

__loading_end(__FILE__)
