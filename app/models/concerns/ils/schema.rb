# app/models/concerns/ils/schema.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

module Ils

  # Values related to the details of serialization/de-serialization.
  #
  module Schema

    # The implemented serializer types.
    #
    # @type [Array<Symbol>]
    #
    SERIALIZER_TYPES = %i[json xml hash].freeze

    # The default serializer type.
    #
    # @type [Symbol]
    #
    DEFAULT_SERIALIZER_TYPE = :json

    # Possible relationships between a schema element defined by 'attribute',
    # 'has_one' or 'has_many' and the name of the serialized data element.
    #
    # @type [Array<Symbol>]
    #
    # @example For "attribute :the_attribute_name":
    #   :default =>
    #       JSON: { "the_attribute_name": "value" }
    #       XML:  '<the_attribute_name>value</the_attribute_name>'
    #   :underscore =>
    #       JSON: { "the_attribute_name": "value" }
    #       XML:  '<the_attribute_name>value</the_attribute_name>'
    #   :camelcase =>
    #       JSON: { "theAttributeName": "value" }
    #       XML:  '<theAttributeName>value</theAttributeName>'
    #   :full_camelcase =>
    #       JSON: { "TheAttributeName": "value" }
    #       XML:  '<TheAttributeName>value</TheAttributeName>'
    #
    # @example For "has_one :elementRecord":
    #   :default =>
    #       JSON: "elementRecord" : { ... }
    #       XML:  '<elementRecord>...</elementRecord>'
    #   :underscore =>
    #       JSON: "element_record" : { ... }
    #       XML:  '<element_record>...</element_record>'
    #   :camelcase  =>
    #       JSON: "elementRecord" : { ... }
    #       XML:  '<elementRecord>...</elementRecord>'
    #   :full_camelcase =>
    #       JSON: "ElementRecord" : { ... }
    #       XML:  '<ElementRecord>value</ElementRecord>'
    #
    ELEMENT_NAMING_MODES =
      %i[default underscore camelcase full_camelcase].freeze

    # The selected element naming mode.
    #
    # @type [Symbol]
    #
    ELEMENT_NAMING_MODE = :camelcase

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Determine the format of the data.
    #
    # @param [String, Hash] data
    #
    # @return [Symbol]                  One of Ils::Schema#SERIALIZER_TYPES
    # @return [nil]                     Otherwise
    #
    def format_of(data)
      if data.is_a?(Hash)
        :hash
      elsif data =~ /^\s*</
        :xml
      elsif data =~ /^\s*[{\[]/
        :json
      end
    end

  end

end

__loading_end(__FILE__)
