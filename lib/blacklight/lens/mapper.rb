# lib/blacklight/lens/mapper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'concerns/config/_base'

module Blacklight::Lens

  # Blacklight::Lens::Mapper
  #
  module Mapper

    include Blacklight::Lens::Config

    # Used to determine whether to interpret a name as one that includes a
    # Blacklight lens name within it (as opposed to a name which is more likely
    # a document ID).
    #
    # @see self#key_for_name
    #
    KEY_PATH_HINT =
      Regexp.new((%w(/ :: Controller) + LENS_KEYS.map(&:to_s)).join('|'), true)

    # Used to determine whether to interpret a name as one that as a document
    # ID by eliminating strings with invalid characters.
    #
    # @see self#key_for_name
    #
    DOC_ID_HINT = /^[^<>#]+$/

    # =========================================================================
    # :section:
    # =========================================================================

    public

    # Translate an entity to a lens key.
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    # @param [TrueClass, FalseClass, Symbol] default
    #
    # @return [Symbol]
    # @return [default] If *name* is invalid and *default* is not a Boolean.
    # @return [nil]     If *name* is invalid and *default* is *false*.
    #
    def key_for(name, default = true)
      if name
        case name
          when Array                    then key_for(name.first, default)
          when ::Config::Base           then name.key
          when Blacklight::Lens::Entry  then name.key
          when Blacklight::Document     then key_for_doc(name, default)
          when Blacklight::Controller   then key_for_name(name.class, default)
          else                               key_for_name(name, default)
        end
      elsif default.is_a?(TrueClass)
        default_key
      elsif !default.is_a?(FalseClass)
        default
      end
    end

    # Given a generic lens key based on the nature of the provided document.
    #
    # @param [Blacklight::Document, String]  doc
    # @param [TrueClass, FalseClass, Symbol] default
    #
    # @return [Symbol]
    # @return [default] If *doc* is invalid and *default* is not a Boolean.
    # @return [nil]     If *doc* is invalid and *default* is *false*.
    #
    # == Implementation Notes
    # The method assumes that :articles is the only lens that handles items of
    # type EdsDocument.
    #
    def key_for_doc(doc, default = true)
      case doc
        when EdsDocument
          ::Config::Articles.key
        when SolrDocument
          ::Config::Catalog.key
        when Blacklight::Document, String, Symbol
          if (doc.respond_to?(:id) ? doc.id : doc).to_s.include?('__')
            ::Config::Articles.key
          else
            ::Config::Catalog.key
          end
        else
          case default
            when false then nil
            when true  then default_key
            else            default
          end
      end
    end

    # Translate a named item to a lens key.
    #
    # If the name is derived from the current controller then the method will
    # attempt to strip off name variations to find the core name (for example,
    # 'video_advanced' will result in 'video'; 'articles_suggest' will result
    # in 'articles', etc).
    #
    # @param [String, Symbol, Class, Config::Base, Blacklight::Controller] name
    # @param [TrueClass, FalseClass, Symbol] default
    #
    # @return [Symbol]
    # @return [default] If *doc* is invalid and *default* is not a Boolean.
    # @return [nil]     If *doc* is invalid and *default* is *false*.
    #
    def key_for_name(name, default = true)
      name = name.to_s.strip
      result =
        case name
          when KEY_PATH_HINT
            name.underscore
              .sub(%r{^.*/([^/]+)$}, '\1') # 'devise/catalog' -> 'catalog'
              .sub(/^config/, '')          # 'config_video'   -> '_video'
              .sub(/^[:_]*/, '')           # '_catalog'       -> 'catalog'
              .sub(/^([^:_]+).*$/, '\1')   # music_suggest_controller -> music
              .sub(/^article$/, '\0s')     # 'article'        -> 'articles'
              .to_sym
          when DOC_ID_HINT
            key_for_doc(name, false)
        end
      if valid_key?(result)
        result
      elsif default.is_a?(TrueClass)
        default_key
      elsif !default.is_a?(FalseClass)
        default
      end
    end

  end

end

__loading_end(__FILE__)
