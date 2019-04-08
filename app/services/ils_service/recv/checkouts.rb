# app/services/ils_service/recv/checkouts.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::Checkouts

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get patron checkouts from Sirsi.
    #
    # @param [String, User, Ils::User] user
    # @param [Hash, nil]               opt
    #
    # @return [IlsCheckouts]
    #
    def get_checkouts(user, **opt)
      return unless (cid = account_id(user))
      get_data('users', cid, 'checkouts', opt)
      data = response&.body&.presence
      IlsCheckouts.new(data, error: @exception)
    end

  end

end

__loading_end(__FILE__)
