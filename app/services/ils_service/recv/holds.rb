# app/services/ils_service/recv/holds.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::Holds

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get patron holds from Sirsi.
    #
    # @param [String, User, Ils::User] user
    # @param [Hash, nil]               opt
    #
    # @return [IlsHolds]
    #
    def get_holds(user, **opt)
      return unless (cid = account_id(user))
      get_data('users', cid, 'holds', opt)
      data = response&.body&.presence
      IlsHolds.new(data, error: @exception)
    end

  end

end

__loading_end(__FILE__)
