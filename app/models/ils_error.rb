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

  delegate_missing_to :violation

end

__loading_end(__FILE__)
