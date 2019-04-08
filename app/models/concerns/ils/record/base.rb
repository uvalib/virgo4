# app/models/concerns/ils/record/base.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/record'
require 'ils/common'

# The base class for objects that interact with the ILS Connector API, either
# to be initialized through de-serialized data received from the API or to be
# serialized into data to be sent to the API.
#
class Ils::Record::Base

  include Ils::Common
  include Ils::Schema
  include Ils::Record::Associations
  include Ils::Record::Schema

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # @return [Symbol]
  attr_reader :serializer_type

  # @return [Exception, nil]
  attr_reader :exception

  # Initialize a new instance.
  #
  # @param [Hash, String, nil] data
  # @param [Hash, nil]         opt
  #
  # @option options [Symbol] :format    One of Ils::Schema#SERIALIZER_TYPES.
  #
  def initialize(data = nil, **opt)
    @exception =
      case opt[:error]
        when Exception then opt[:error]
        when String    then Exception.new(opt[:error])
      end
    if @exception
      @serializer_type = :hash
      initialize_attributes
    else
      @serializer_type = opt[:format] || DEFAULT_SERIALIZER_TYPE
      assert_serializer_type(@serializer_type)
      deserialize(data)
    end
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # A serializer instance of the currently-selected type.
  #
  # @return [Ils::Serializer::Base]
  #
  def serializer
    @serializer ||= self.class.serializers[serializer_type].new(self)
  end

  # Load data elements from the supplied data.
  #
  # (If the data is a String, it must already be in JSON format.)
  #
  # @param [String, Hash] data
  #
  # @return [Ils::Record::Base]
  # @return [nil]
  #
  def deserialize(data)
    serializer.deserialize(data)
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  public

  # Returns *nil* unless this instance is an error placeholder.
  #
  # @return [String, nil]
  #
  def error_message
    exception&.message
  end

  # Indicate whether this is an instance created as part of a placeholder
  # generated due to a failure to acquire valid data from the source.
  #
  def error?
    exception.present?
  end

  # Indicate whether this is a valid data instance.
  #
  def valid?
    !error?
  end

  # Default data used to initialize an error instance.
  #
  # @return [Hash{Symbol=>BasicObject}]
  #
  # @see Ils::Record::Associations#property_defaults
  #
  def default_data
    self.class.property_defaults.deep_dup
  end

  # ===========================================================================
  # :section:
  # ===========================================================================

  protected

  # Directly assign schema attributes.
  #
  # @param [Hash, nil] data           Default: #default_data
  #
  # @return [Hash{Symbol=>BasicObject}]
  #
  # == Usage Notes
  # This is only intended for use in the initialization of an error instance.
  #
  def initialize_attributes(data = nil)
    (data || default_data).each_pair do |attr, value|
      case value
        when Class then value = value.new
        when Proc  then value = value.call(error: exception)
      end
      send(:"#{attr}=", value)
    end
  end

end

__loading_end(__FILE__)
