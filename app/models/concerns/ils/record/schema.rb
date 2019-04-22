# app/models/concerns/ils/record/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'

# Definitions used within the #schema block when it is executed in the context
# of the class which includes this module.
#
# Definition of the #schema method which defines the serializable data elements
# for the including class.
#
module Ils::Record::Schema

  extend ActiveSupport::Concern

  module ClassMethods

    include Ils::Schema

    # The serializers for the including class.
    #
    # @return [Hash{Symbol=>Ils::Serializer::Base}]
    #
    attr_reader :serializers

    # The JSON serializer for the including class.
    #
    # @return [Ils::Serializer::JsonBase]
    #
    def json_serializer
      serializers[:json]
    end

    # The XML serializer for the including class.
    #
    # @return [Ils::Serializer::XmlBase]
    #
    def xml_serializer
      serializers[:xml]
    end

    # The Hash serializer for the including class.
    #
    # @return [Ils::Serializer::HashBase]
    #
    def hash_serializer
      serializers[:hash]
    end

    # Schema definition block method.
    #
    # This method is used within the definition of a class derived from
    # Ils::Record::Base to specify its serializable data elements within the
    # block supplied to the method.
    #
    # In addition, class-specific serializers are created using these data
    # element definitions.
    #
    # @param [Array<Symbol>, nil] serializer_types
    #
    # @see Ils::Schema#SERIALIZER_TYPES
    # @see Ils::Serializer::Associations::ClassMethods#attribute
    # @see Ils::Serializer::Associations::ClassMethods#has_one
    # @see Ils::Serializer::Associations::ClassMethods#has_many
    #
    def schema(*serializer_types, &block)
      # Add record field definitions to the class itself.
      class_exec(&block)
      # Add record field definitions to each format-specific serializer.
      @serializers =
        (serializer_types.presence || SERIALIZER_TYPES).map { |key|
          key  = key.downcase.to_sym if key.is_a?(String)
          type = key.to_s.capitalize
          base = "Ils::Serializer::#{type}Base".constantize
          serializer = Class.new(base, &block)
          [key, const_set("#{type}Serializer", serializer)]
        }.to_h
    end

  end

end

__loading_end(__FILE__)
