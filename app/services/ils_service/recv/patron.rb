# app/services/ils_service/recv/patron.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../recv'

class IlsService

  module Recv::Patron

    include Recv

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Get patron account information from Sirsi.
    #
    # @param [String, User, Ils::User] user
    # @param [Hash, nil]               opt
    #
    # @return [IlsPatron]
    #
    def get_patron(user, **opt)
      return unless (cid = account_id(user))
      get_data('users', cid, opt)
      data = response&.body&.presence
      IlsPatron.new(data, error: @exception)
    end

  end

end

__loading_end(__FILE__)
