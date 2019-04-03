# app/models/concerns/ils/error.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Ils

  # Base exception for ILS errors.
  #
  class Error < RuntimeError

    # If applicable, the original exception that was rescued which resulted in
    # raising an Ils::Error exception.
    #
    # @return [Exception]
    # @return [nil]
    #
    attr_reader :original_exception

    # Initialize a new instance.
    #
    # @param [Array<(String,Exception)>] args
    #
    def initialize(*args)
      msg = nil
      while (arg = args.shift)
        case arg
          when String    then msg = arg
          when Exception then @original_exception = arg
        end
      end
      msg ||= @original_exception&.message
      super(msg)
    end

  end

  # ===========================================================================
  # :section: Receive errors
  # ===========================================================================

  public

  # Base exception for ILS receive errors.
  #
  class RecvError < Ils::Error; end

  # Exception raised to indicate a problem with received data.
  #
  class ParseError < Ils::RecvError; end

  # ===========================================================================
  # :section: Transmit errors
  # ===========================================================================

  public

  # Base exception for ILS transmit errors.
  #
  class XmitError < Error; end

  # Base exception for ILS requests.
  #
  class RequestError < XmitError; end

  # Exception raised to indicate a problem requesting a hold.
  #
  class HoldError < RequestError; end

  # Exception raised to indicate a problem requesting a renewal.
  #
  class RenewError < RequestError; end

end

__loading_end(__FILE__)
