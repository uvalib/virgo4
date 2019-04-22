# app/models/concerns/ils/serializer/hash_base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/serializer/base'
require 'ils/serializer/hash_associations'

# Base class for object-specific serializers that process data passed in as a
# Hash.
#
# @see Ils::Record::Schema::ClassMethods#schema
#
class Ils::Serializer::HashBase < Ils::Serializer::Base

  include Representable::Hash
  include Representable::Coercion
  include Ils::Serializer::HashAssociations

  # Symbolize keys in the serialization result by default.
  #
  # @type [Boolean]
  #
  SERIALIZE_SYMBOLIZE_KEYS = true

  # ===========================================================================
  # :section: Ils::Serializer::Base overrides
  # ===========================================================================

  public

  # Render data elements.
  #
  # @param [Symbol, Proc, nil] method
  # @param [Boolean, nil]      symbolize_keys
  #
  # @return [String]
  #
  # This method overrides:
  # @see Ils::Serializer::Base#serialize
  #
  def serialize(method = :to_hash, symbolize_keys: SERIALIZE_SYMBOLIZE_KEYS)
    symbolize_keys ? super.deep_symbolize_keys : super
  end

  # Load data elements.
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
  def deserialize(data, method = :from_hash)
    super
  end

  # ===========================================================================
  # :section: Record field schema DSL
  # ===========================================================================

  public

  if defined?(HASH_ELEMENT_NAMING_MODE)
    defaults do |name|
      { as: element_name(name, HASH_ELEMENT_NAMING_MODE) }
    end
  end

end

__loading_end(__FILE__)
