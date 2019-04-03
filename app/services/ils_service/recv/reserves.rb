# app/services/ils_service/recv/reserves.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::Reserves

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get patron course reserves from Sirsi.
    #
    # @param [String, User, Ils::User] user
    # @param [Hash, nil]               opt
    #
    # @return [IlsReserves]
    #
    def get_reserves(user, **opt)
      return unless (cid = account_id(user))
      get_data('users', cid, 'reserves', opt)
      data = response&.body&.presence
      IlsReserves.new(data, error: @exception)
    end

  end

end

__loading_end(__FILE__)
