# app/models/ils/home_location.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/location_methods'
require 'ils/summary'

# Ils::HomeLocation
#
# @attr [Integer] id
# @attr [String]  code
#
# @attr [String]  name
#
# @see Ils::LocationMethods
#
class Ils::HomeLocation < Ils::Record::Base

  schema do

    attribute :id,   Integer
    attribute :code, String

    has_one   :name, String

  end

  include Ils::LocationMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Array<Ils::Summary>]
  attr_accessor :summaries

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         options
  #
  def initialize(data = nil, **options)
    @summaries = []
    if (_name = options[:name]) || (_code = options[:code])
      if _name && !_code
        n, c = lookup(_name)
        _name = n if n
        _code = c || n
      end
      options = options.except(:name, :code)
    elsif data.is_a?(Hash) && ((_name = data[:name]) || (_code = data[:code]))
      if _name && !_code
        n, c = lookup(_name)
        _name = n if n
        _code = c || n
        data = data.merge(name: _name) if _name
        data = data.merge(code: _code) if _code
      end
      _name = _code = nil
    end
    super(data, options)
    self.name = _name if _name
    self.code = _code if _code
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add a holdings summary line.
  #
  # @param [String] call_number
  # @param [String] text
  # @param [String] note
  #
  # @return [Ils::Summary]            The added summary line.
  #
  def add_summary_line(call_number, text, note)
    Ils::Summary.new(call_number, text, note).tap do |line|
      summaries << line
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  private

  # Find a location with a matching name or code.
  #
  # @param [String] name
  #
  # @return [Array<(String,String>)]
  #
  def lookup(name)
    loc = nil # TODO: Periodic refresh of location database table
=begin
    loc = IlsLocationList.lookup(name)
=end
    return loc.name, loc.code if loc.present?
  end

end

__loading_end(__FILE__)
