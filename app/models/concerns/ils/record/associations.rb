# app/models/concerns/ils/record/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
module Ils::Record::Associations

  extend ActiveSupport::Concern

  # Although arguments to #attribute, #has_one, and #has_many are ignored in
  # this context, this constant must be given a definition so that Ruby may
  # parse the code.
  Boolean = TrueClass

  module ClassMethods

    include Ils::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # In the context of a class derived from Ils::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @return [void]
    #
    # @see Ils::Serializer::Associations::ClassMethods#attribute
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    def attribute(*args)
      attr_accessor(args.first)
    end

    # In the context of a class derived from Ils::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @return [void]
    #
    # @see Ils::Serializer::Associations::ClassMethods#has_one
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    def has_one(*args)
      attr_accessor(args.first)
    end

    # In the context of a class derived from Ils::Record::Base, this definition
    # allows the method to be mapped directly to Module#attr_accessor.
    #
    # @return [void]
    #
    # @see Ils::Serializer::Associations::ClassMethods#has_one
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    def has_many(*args)
      attr_accessor(args.first)
    end

  end

end

__loading_end(__FILE__)
