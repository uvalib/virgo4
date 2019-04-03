# app/models/concerns/ils/serializer/associations.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/serializer'

# Definitions used within the #schema block when it is executed in the context
# of a serializer class definition.
#
module Ils::Serializer::Associations

  extend ActiveSupport::Concern

  # The options to #attribute, #has_one, or #has_many definitions which
  # indicate the specification of a type for the element or (in the case of
  # #has_many) its constituent parts.
  #
  # @type [Array<Symbol>]
  #
  TYPE_OPTION_KEYS = %i[type extend decorator].freeze

  # The types that may be given as the second argument to #attribute, #has_one,
  # or #has_many definitions.
  #
  # @type [Hash{Symbol=>Object}]
  #
  SCALAR_DEFAULTS = {
    '':          '',
    Boolean:     false,
    Date:        Date.new,
    DateTime:    DateTime.new,
    FalseClass:  false,
    Float:       0.0,
    Integer:     0,
    Numeric:     0,
    String:      '',
    Symbol:      :'',
    TrueClass:   true,
  }.freeze

  # The types that may be given as the second argument to #attribute, #has_one,
  # or #has_many definitions.
  #
  # @type [Array<Symbol>]
  #
  SCALAR_TYPES = SCALAR_DEFAULTS.keys.freeze

  # The maximum number of elements within a collection.
  #
  # @type [Integer]
  #
  # == Usage Notes
  # This is not currently an enforced maximum -- it's only used to distinguish
  # between #has_one and #has_many.
  #
  MAX_HAS_MANY_COUNT = 9999

  module ClassMethods

    include Ils::Schema

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    public

    # Simulate ActiveRecord::Attributes#attribute to define a data element that
    # is handled as an attribute.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Ils::Record::Base; schema { attribute :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Ils::Record::Base; schema { attribute :elem }; end  -->
    #     <XXX elem="value"></XXX>
    #
    def attribute(name, type = nil, **opt)
      # If the type is missing or explicitly "String" then *type* will be
      # returned as *nil*.
      type, opt  = get_type_opt(nil, type, opt)
      opt[:type] = type if type

      # Ensure that attributes get a type-appropriate default (otherwise they
      # will just be *nil*).
      opt[:default] ||= SCALAR_DEFAULTS[type.to_s.demodulize.to_sym]

      prepare_attribute!(type, opt)

      property(name, opt)
    end

    # Simulate ActiveRecord::Associations#has_one to define a data element that
    # is handled as a singleton element.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Ils::Record::Base; schema { has_one :elem }; end  -->
    #     "XXX" : { "elem" : "value" }
    #
    # @example XML:
    #   class XXX < Ils::Record::Base; schema { attribute :elem }; end  -->
    #     <XXX><elem>value</elem></XXX>
    #
    def has_one(name, type = nil, **opt, &block)
      type, opt = get_type_opt(name, type, opt)
      if scalar_type?(type)
        opt[:attribute] = false
        attribute(name, type, opt)
        Rails.logger.warn("#{__method__}: block not processed") if block_given?
      else
        has_many(name, type, 1, opt, &block)
      end
    end

    # Simulate ActiveRecord::Associations#has_many to define a data element
    # collection.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Numeric, nil]               count
    # @param [Hash, nil]                  opt
    #
    # @return [void]
    #
    # @see Ils::Record::Schema::ClassMethods#schema
    #
    # == Examples
    # @example JSON:
    #   class XXX < Ils::Record::Base; schema { has_many :elem }; end  -->
    #     "XXX" : { "elem" : [...] }
    #
    # @example XML (WRAP_COLLECTIONS = true)
    #   class XXX < Ils::Record::Base; schema { has_many :elem }; end  -->
    #     <XXX><elems><elem>...</elem>...<elem>...</elem></elems></XXX>
    #
    # @example XML (WRAP_COLLECTIONS = false)
    #   class XXX < Ils::Record::Base; schema { has_many :elem }; end  -->
    #     <XXX><elem>...</elem>...<elem>...</elem></XXX>
    #
    def has_many(name, type = nil, count = MAX_HAS_MANY_COUNT, **opt, &block)
      type, opt = get_type_opt(name, type, opt)
      type ||= Axiom::Types::String

      if scalar_type?(type)
        opt[:type]      = type
      else
        opt[:class]     = type
        opt[:decorator] = decorator_class(type)
      end

      unless count == 1
        opt[:collection] = true
        prepare_collection!(name, type, opt)
      end

      property(name, opt, &block)
    end

    # =========================================================================
    # :section: Record field schema DSL
    # =========================================================================

    protected

    # Determine the class to be associated with a data element.
    #
    # @param [Symbol]                     name
    # @param [Class, String, Symbol, nil] type
    # @param [Hash, nil]                  opt
    #
    # @return [Array<(Class, Hash)>]
    # @return [Array<(nil,   Hash)>]
    #
    def get_type_opt(name, type, opt)
      opt  = opt.dup
      type = opt.extract!(*TYPE_OPTION_KEYS).values.first || type || name
      type = type.to_s.classify if type.is_a?(Symbol)
      name = type.to_s.demodulize
      if name.blank? || (name == 'String')
        type = nil
      elsif SCALAR_TYPES.include?(name.to_sym)
        name = 'Boolean' if %w(TrueClass FalseClass).include?(name)
        type = "Axiom::Types::#{name}"
      elsif !(name = type.to_s).include?('::')
        type = "Ils::#{name}"
      end
      type = type.constantize if type.is_a?(String)
      return type, opt
    end

    # Indicate whether the type is a scalar (not a representer) class.
    #
    # @param [Class, nil] type
    #
    # @return [Symbol]
    #
    def scalar_type?(type)
      name = type.to_s.demodulize.to_sym
      SCALAR_TYPES.include?(name) || (type.parent == Object)
    end

    # decorator_class
    #
    # @param [Class, String] record_class
    #
    # @return [Proc]
    #
    # @see Ils::Serializer::Base#serializer_type
    #
    def decorator_class(record_class)
      ->(*) {
        format = serializer_type.to_s.capitalize
        "#{record_class}::#{format}Serializer".constantize
      }
    end

    # element_name
    #
    # @param [String, Symbol] name
    # @param [Symbol, nil]    mode
    #
    # @return [String]
    #
    def element_name(name, mode = nil)
      name = name.to_s
      case mode
        when :underscore     then name = name.underscore
        when :camelcase      then name = name.camelcase(:lower)
        when :full_camelcase then name = name.camelcase(:upper)
      end
      name
    end

    # Format-specific operations for #attribute data elements.
    #
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  _options
    #
    # @return [void]
    #
    def prepare_attribute!(_element, _options)
    end

    # Format-specific operations for #has_many data elements.
    #
    # @param [String, Symbol]        _wrapper
    # @param [String, Symbol, Class] _element
    # @param [Hash]                  _options
    #
    # @return [void]
    #
    def prepare_collection!(_wrapper, _element, _options)
    end

  end

end

__loading_end(__FILE__)
