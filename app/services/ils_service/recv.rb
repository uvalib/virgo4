# app/services/ils_service/recv.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class IlsService

  module Recv

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Produce an error message from an HTTP response.
    #
    # @param [Symbol, String] method    For log messages.
    # @param [Exception, nil] error     Default: @error.
    #
    # @return [String]
    # @return [nil]                     If there was no error.
    #
    def receive_error_message(method = nil, error = @error)
      return unless error
      Rails.logger.info("ILS #{method}: #{error}")
      error.to_s
    end

  end

end

__loading_end(__FILE__)
