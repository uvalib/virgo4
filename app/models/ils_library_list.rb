# app/models/ils_library_list.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/message'
require 'ils/library'

# IlsLibraryList
#
# @attr [Array<Ils::Library>] libraries
#
class IlsLibraryList < Ils::Message

  schema do

    has_many :libraries, wrap: true

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
    self.libraries = [] if error?
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Find a library with a matching name or code.
  #
  # @param [String] name
  #
  # @return [Ils::Library, nil]
  #
  def lookup(name)
    (libraries || []).find do |v|
      v.name.casecmp(name).zero? || (v.code == name)
    end
  end

  # The list of deliverable libraries in the form needed for populating a
  # drop-down list.
  #
  # @return [Array<Array<(String,String)>>]
  #
  def names_and_ids
    all(deliverable: true)
  end

  # The list of libraries in the form needed for populating a drop-down list.
  #
  # @param [Hash] opt
  #
  # @option [Boolean] :leoable      Note [1]
  # @option [Boolean] :deliverable  Note [2]
  # @option [Boolean] :holdable     Note [3]
  # @option [Boolean] :remote       Note [4]
  # @option [Boolean] :on_grounds   Note [5]
  #
  # @return [Array<Array<(String,String)>>]
  #
  # == Usage Notes
  # [1] :leoable => Only libraries from which LEO can pick up.
  # [2] :deliverable => Only libraries with a location where holds and other
  #       requested items can be picked up.
  # [3] :holdable => Only libraries whose items are generally capable of
  #       having a hold placed on them.
  # [4] :remote => Only libraries that are not easily available from UVA
  #       proper.  NOTE: Special Collections is treated as such.
  # [5] :on_grounds => The inverse of :remote -- libraries that are easily
  #       available from UVA grounds.
  #
  def all(opt = nil)
    opt ||= {}
    (libraries.sort_by!(&:name) || []).map { |library|
      not_included =
        opt.find do |condition, requirement|
          case condition
            when :leoable     then library.leoable?     != requirement
            when :deliverable then library.deliverable? != requirement
            when :holdable    then library.holdable?    != requirement
            when :remote      then library.remote?      != requirement
            when :on_grounds  then library.remote?      == requirement
          end
        end
      [library.name, library.id] unless not_included
    }.compact
  end

  # ===========================================================================
  # :section: Class methods
  # ===========================================================================

  public

  class << self

    # All libraries reported by Sirsi.
    #
    # @return [IlsLibraryList]
    # @return [nil]                   If the data could not be acquired.
    #
    # @see #refresh
    #
    def all
      @all ||= refresh
    end

    # All libraries reported by Sirsi.
    #
    # @return [IlsLibraryList]
    # @return [nil]                   If the data could not be acquired.
    #
    # @see IlsService#get_library_list
    #
    def refresh
      @all = IlsService.new.get_library_list
    end

    # Find a library with a matching name or code.
    #
    # @param [String] name
    #
    # @return [Ils::Library, nil]
    #
    # @see IlsLibraryList#lookup
    #
    def lookup(name)
      all.lookup(name)
    end

  end

end

__loading_end(__FILE__)
