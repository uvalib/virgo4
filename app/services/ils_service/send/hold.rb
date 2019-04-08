# app/services/ils_service/send/hold.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require_relative '../send'

class IlsService

  module Send::Hold

    include Send

    # @type [Hash{Symbol=>String}]
    ILS_HOLD_MESSAGE = {

      no_items:      'There were no items to request',
      not_cataloged: 'This item is not available for requests yet',
      failed:        'Unable to request items right now',

    }.reverse_merge(ILS_SEND_MESSAGE).freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    ILS_HOLD_RESPONSE = {

      no_items:       'no items',
      not_cataloged:  'does not exist',
      failed:         nil

    }.reverse_merge(ILS_SEND_RESPONSE).freeze

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Request a hold/recall of an item on behalf of a given patron.
    #
    # @param [String, User, Ils::User] user
    # @param [String]                  doc_id
    # @param [String]                  lib_id
    # @param [String, nil]             call_number
    #
    # @return [String]
    #
    # @raise [Ils::HoldError]
    #
    def place_hold(user:, doc_id:, lib_id:, call_number: nil)
      return unless (cid = account_id(user)) && (ckey = to_ckey(doc_id))
      params = {
        computingId:     cid,
        catalogId:       ckey,
        pickupLibraryId: lib_id,
      }
      params[:callNumber] = call_number if call_number.present?
      post_data('request', 'hold', params)
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
      # TODO: rescue handler for HoldError
      raise Ils::HoldError,
        request_error_message(method, ILS_HOLD_RESPONSE, ILS_HOLD_MESSAGE)
    end

  end

end

__loading_end(__FILE__)
