# app/models/concerns/ils/serializer/json_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/serializer/base'
require 'ils/serializer/json_associations'

# Base class for object-specific serializers that process JSON data.
#
# @see Ils::Record::Schema::ClassMethods#schema
#
class Ils::Serializer::JsonBase < Ils::Serializer::Base

  include Representable::JSON
  include Representable::Coercion
  include Ils::Serializer::JsonAssociations

  # ===========================================================================
  # :section: Ils::Serializer::Base overrides
  # ===========================================================================

  public

  # Render data elements in JSON format.
  #
  # @param [Symbol, Proc, nil] method
  #
  # @return [String]
  #
  # This method overrides:
  # @see Ils::Serializer::Base#serialize
  #
  def serialize(method = :to_json)
    super
  end

  # Load data elements from the supplied data in JSON format.
  #
  # @param [String, Hash]      data
  # @param [Symbol, Proc, nil] method
  #
  # @return [Hash]
  # @return [nil]
  #
  # This method overrides:
  # @see Ils::Serializer::Base#deserialize
  #
  def deserialize(data, method = :from_json)
    super
  end

  # ===========================================================================
  # :section: Ils::Serializer::Base overrides
  # ===========================================================================

  protected

  # Set source data string for JSON data.
  #
  # @param [String, Hash] data
  #
  # @return [String]
  # @return [nil]                 If *data* is neither a String nor a Hash.
  #
  # This method overrides:
  # @see Ils::Serializer::Base#set_source_data
  #
  def set_source_data(data)
    @source_data ||=
      if data.is_a?(String)
        data.dup
      elsif data
        data.to_json
      end
  end

  # ===========================================================================
  # :section: Record field schema DSL
  # ===========================================================================

  public

  if defined?(JSON_ELEMENT_NAMING_MODE)
    defaults do |name|
      { as: element_name(name, JSON_ELEMENT_NAMING_MODE) }
    end
  end

end

__loading_end(__FILE__)
