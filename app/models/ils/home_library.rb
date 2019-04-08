# app/models/ils/home_library.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/library_methods'
require 'ils/home_location'

# Ils::HomeLibrary
#
# @attr [Integer] id
# @attr [String]  code
#
# @attr [String]  name
# @attr [Boolean] deliverable
# @attr [Boolean] holdable
#
# @see Ils::LibraryMethods
#
class Ils::HomeLibrary < Ils::Record::Base

  schema do

    attribute :id,          Integer
    attribute :code,        String

    has_one   :name,        String
    has_one   :deliverable, Boolean
    has_one   :holdable,    Boolean

  end

  include Ils::LibraryMethods

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Array<Ils::HomeLocation>]
  attr_accessor :summary_locations

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         opt
  #
  def initialize(data = nil, **opt)
    @summary_locations = []
    if (_name = opt[:name]) || (_code = opt[:code])
      if _name && !_code
        n, c = lookup(_name)
        _name = n if n
        _code = c || n
      end
      opt = opt.except(:name, :code)
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
    super(data, opt)
    self.name = _name if _name
    self.code = _code if _code
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Add a holdings summary line.
  #
  # @param [String] location_name
  # @param [String] call_number
  # @param [String] text
  # @param [String] note
  #
  # @return [Array<Ils::HomeLocation>]  The updated #summary_locations array.
  # @return [nil]                       If the location was invalid.
  #
  def add_summary_line(location_name, call_number, text, note)
    loc = find_location(location_name) || add_location(location_name)
    loc.add_summary_line(call_number, text, note) if loc
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Find a summary location entry.
  #
  # @param [String] name
  #
  # @return [Ils::HomeLocation]       The summary location entry.
  # @return [nil]                     If *name* could not be found.
  #
  def find_location(name)
    summary_locations.find { |loc| loc.identifier?(name) }
  end

  # Add a summary location.
  #
  # @param [String]    name
  # @param [Hash, nil] opt
  #
  # @return [Ils::HomeLocation]       The new summary location entry.
  #
  def add_location(name, **opt)
    Ils::HomeLocation.new(name: name, **opt).tap do |loc|
      summary_locations << loc
    end
  end

  # Find a library with a matching name or code.
  #
  # @param [String] name
  #
  # @return [Array<(String,String>)]
  #
  def lookup(name)
    lib = nil # TODO: Periodic refresh of library database table
=begin
    lib = IlsLibraryList.lookup(name)
=end
    return lib.name, lib.code if lib.present?
  end

end

__loading_end(__FILE__)
