# app/models/ils/summary.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/common'

# Ils::Summary
#
class Ils::Summary

  include Ils::Common

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [String]
  attr_accessor :call_number

  # @return [String]
  attr_accessor :text

  # @return [String]
  attr_accessor :note

  # Initialize a new instance.
  #
  # @param [String] call_number
  # @param [String] text
  # @param [String] note
  #
  def initialize(call_number, text, note)
    @call_number = call_number
    @text        = format_text(text)
    add_brackets = @call_number.present? || @text.present?
    @note        = format_note(note, add_brackets)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # format_text
  #
  # @param [String] s
  #
  # @return [String]
  #
  def format_text(s)
    s.to_s
      .chomp(',')
      .gsub(/[:;,)\]}]/, '\0 ')
      .gsub(/[(\[{]/, ' \0')
      .gsub(%r{[/-]}, ' \0 ')
      .gsub(/([a-z])\.(\d)/i, '\1. \2')
      .gsub(/(\d)\s*(-)\s*(\d)/, '\1\2\3')
      .gsub(%r{(\d{4})\s*(/)\s*(\d{4})}, '\1\2\3')
      .squish
  end

  # format_note
  #
  # @param [String]       s
  # @param [Boolean, nil] add_brackets
  #
  # @return [String]
  #
  def format_note(s, add_brackets = false)
    result = s.to_s.chomp(',').squish
    if add_brackets
      result.sub!(/^\((.*)\)$/, '[\1]')
      result.sub!(/^[^\[].*[^\]]$/, '[\0]')
    end
    result
  end

end

__loading_end(__FILE__)
