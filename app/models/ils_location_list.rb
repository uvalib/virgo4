# app/models/ils_location_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/location'

# IlsLocationList
#
# @attr [Array<Ils::Location>] locations
#
class IlsLocationList < Ils::Message

  schema do

    has_many :locations, wrap: true

  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Initialize a new instance.
  #
  # @param [Hash, String] data
  # @param [Hash, nil]    opt
  #
  # @option options [Symbol] :format
  #
  # This method overrides:
  # @see Ils::Record::Base#initialize
  #
  def initialize(data, **opt)
    super
    self.locations = [] if error?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Find a location with a matching name or code.
  #
  # @param [String] name
  #
  # @return [Ils::Location, nil]
  #
  def lookup(name)
    (locations || []).find do |v|
      v.name.casecmp(name).zero? || (v.code == name)
    end
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  class << self

    # All locations reported by Sirsi.
    #
    # @return [IlsLocationList]
    # @return [nil]                   If the data could not be acquired.
    #
    # @see #refresh
    #
    def all
      @all ||= refresh
    end

    # All locations reported by Sirsi.
    #
    # @return [IlsLocationList]
    # @return [nil]                   If the data could not be acquired.
    #
    # @see IlsService#get_location_list
    #
    def refresh
      @all = IlsService.new.get_location_list
    end

    # Find a location with a matching name or code.
    #
    # @param [String] name
    #
    # @return [Ils::Location, nil]
    #
    # @see IlsLocationList#lookup
    #
    def lookup(name)
      all.lookup(name)
    end

  end

end

__loading_end(__FILE__)
