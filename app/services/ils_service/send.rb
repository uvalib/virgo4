# app/services/ils_service/send.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class IlsService

  module Send

    # @type [Hash{Symbol=>String}]
    ILS_SEND_MESSAGE = {
      default: 'Bad response from server',
    }.freeze

    # @type [Hash{Symbol=>(String,Regexp,nil)}]
    ILS_SEND_RESPONSE = {
      default: nil
    }.freeze

    # =========================================================================
    # :section:
    # =========================================================================

    protected

    # Produce an error message from an HTTP response.
    #
    # @param [Symbol, String]         method          For log messages.
    # @param [Hash, nil]              response_table
    # @param [Hash, nil]              template_table
    # @param [Net::HTTPResponse, nil] response        Default: @response.
    #
    # @return [String]
    #
    def request_error_message(
      method          = nil,
      response_table  = nil,
      template_table  = nil,
      response        = @response
    )
      # Extract information from the HTTP response.
      body    = response&.body&.presence
      error   = body && IlsError.new(body)
      code    = error&.code
      message = error&.message&.presence
      level   = message ? Logger::WARN : Logger::Error

      # Generate a message if one was not provided in the received data.
      message ||=
        if response.blank?
          'no HTTP result'
        elsif body.blank?
          'empty HTTP result body'
        elsif body.include?('Exception')
          'ILS Connector internal server error'
        else
          'unknown failure'
        end

      # Log the warning/error.
      Rails.logger.log(level) do
        log = ["ILS #{method}: #{message}"]
        log << "code #{code.inspect}"
        log << "body #{body}" if body.present?
        log.join('; ')
      end

      # Get the message template which matches *message*.
      template =
        if template_table.present?
          key =
            response_table&.find { |_, pattern|
              case pattern
                when nil    then true
                when String then message.include?(pattern)
                when Regexp then message =~ pattern
              end
            }&.first
          template_table[key] || template_table[:default]
        end

      # Include the message from received data.
      if template.blank?
        message
      elsif template.include?('%')
        template % message
      else
        "#{template}: #{message}"
      end
    end

  end

end

__loading_end(__FILE__)
