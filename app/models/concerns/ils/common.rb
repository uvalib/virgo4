# app/models/concerns/ils/common.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Ils

  # Shared values and methods.
  #
  module Common

    extend self

    # =========================================================================
    # :section: Class methods
    # =========================================================================

    public

    # Generate a list of String and/or Regexp against which a code value can be
    # matched.
    #
    # @param [Array<String, Regexp, Array>] args
    #
    # @return [Array<String, Regexp>]
    #
    # == Usage Notes
    # This method is intended for class-level constant definitions so it
    # returns a frozen result.
    #
    def codes(*args)
      args.flatten.map { |arg|
        arg = Regexp.new(arg.source, Regexp::IGNORECASE) if arg.is_a?(Regexp)
        arg.to_s.freeze
      }.reject(&:blank?).freeze
    end

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Convert a document ID to a Sirsi "checkout key" identifier.
    #
    # Remove the first character of the catalog key, which is a 'u'.
    # Also remove 'pda' if the catalog key is preceded by that string.
    #
    # @param [String] doc_id
    #
    # @return [String]
    # @return [nil]                   If the ID was not convertible.
    #
    def to_ckey(doc_id)
      doc_id.to_s.sub(/^pda/, '').sub!(/^u(\d+)/, '\1')
    end

    # Convert a Sirsi "checkout key" identifier to a document ID.
    #
    # @param [String] ckey
    #
    # @return [String]
    #
    def from_ckey(ckey)
      "u#{ckey}"
    end

    # date_format
    #
    # @param [Date] date
    #
    # @return [String]
    #
    def date_format(date)
      result = date.strftime('%b %d, %Y')
      result = 'Never' if result == 'Jan 01, 1900'
      result
    end

    # Match a library code or location code against one or more patterns.
    #
    # If *code* is a Symbol, it is translated; e.g. :mt_lake becomes 'MT-LAKE'.
    #
    # @param [String, Symbol]               code
    # @param [Array<String, Regexp, Array>] args
    #
    def match?(code, *args)
      code = code.to_s.dasherize.upcase
      args.flatten.any? { |arg| code.match?(arg) }
    end

    # Normalize a call number into a form for comparison.
    #
    # @param [String] call_number
    #
    # @return [String]
    #
    def comparable(call_number)
      call_number.to_s.delete(' ').downcase
    end

    # Convert a user identity a form usable by Sirsi.
    #
    # @param [String, User, Ils::User] user
    #
    # @return [String, nil]
    #
    def account_id(user)
      case user
        when Ils::User then user.computing_id
        when ::User    then user.login
        else                user.to_s
      end.presence
    end

  end

end

__loading_end(__FILE__)
