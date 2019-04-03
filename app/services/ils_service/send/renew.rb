# app/services/ils_service/send/renew.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../send'

class IlsService

  module Send::Renew

    include Send

    # @type [Hash{Symbol=>String}]
    ILS_RENEW_MESSAGE = {

      no_items: 'There were no items to renew',
      failed:   'Unable to renew all items right now',

    }.reverse_merge(ILS_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    ILS_RENEW_RESPONSE = {

      no_items:  /no items/i,
      failed:    nil

    }.reverse_merge(ILS_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # renew
    #
    # @param [String, User, Ils::User] user
    # @param [String]                  doc_id
    #
    # @return [String]
    # @return [nil]
    #
    # @raise [Ils::RenewError]
    #
    def renew(user:, doc_id:)
      return unless (cid = account_id(user)) && (ckey = to_ckey(doc_id))
      post_data('request', 'renew', computingId: cid, checkoutKey: ckey)
      case @response
        when Net::HTTPSuccess, Net::HTTPRedirection
          @response.body.presence || raise_exception(__method__)
        else
          raise_exception(__method__)
      end
    end

    # renew_all
    #
    # @param [String, User, Ils::User] user
    #
    # @return [String]
    # @return [nil]
    #
    # @raise [Ils::RenewError]
    #
    def renew_all(user:)
      return unless (cid = account_id(user))
      post_data('request', 'renewAll', computingId: cid)
      case @response
        when Net::HTTPSuccess, Net::HTTPRedirection
          @response.body.presence || raise_exception(__method__)
        else
          raise_exception(__method__)
      end
    end

    # =========================================================================
    # :section:
    # =========================================================================

    private

    # raise_exception
    #
    # @param [Symbol, String] method  For log messages.
    #
    def raise_exception(method)
      # TODO: rescue handler for RenewError
      raise Ils::RenewError,
        request_error_message(method, ILS_RENEW_RESPONSE, ILS_RENEW_MESSAGE)
    end

  end

end

__loading_end(__FILE__)
