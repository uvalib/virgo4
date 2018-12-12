# lib/blacklight/lens/configuration/mapper.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'blacklight/lens/configuration/keys'

module Blacklight::Lens

  module Configuration

    # Blacklight::Lens::Configuration::Mapper
    #
    module Mapper

      include Blacklight::Lens::Configuration
      include Keys
      extend  Keys

      # Used to determine whether to interpret a name as one that includes a
      # Blacklight lens name within it (as opposed to a name which is more
      # likely a document ID).
      #
      # @see self#key_for_name
      #
      KEY_PATH_HINT =
        Regexp.new((%w(/ :: Controller) + lens_keys).join('|'), true)

      # Used to determine whether to interpret a name as one that as a document
      # ID by eliminating strings with invalid characters.
      #
      # @see self#key_for_name
      #
      DOC_ID_HINT = /^[^<>#]+$/

      # =======================================================================
      # :section:
      # =======================================================================

      public

      # Translate an entity to a lens key.
      #
      # @param [String, Symbol, Class, Entry, Blacklight::Controller] item
      # @param [TrueClass, FalseClass, Symbol] default
      #
      # @return [Symbol]
      # @return [default] If *item* is invalid and *default* is not a Boolean.
      # @return [nil]     If *item* is invalid and *default* is *false*.
      #
      def key_for(item, default = true)
        return key_for(item.first, default) if item.is_a?(Array)
        case item
          when Entry                  then item.key
          when Blacklight::Document   then key_for_doc(item, default)
          when Blacklight::Controller then key_for_name(item.class, default)
          else                             key_for_name(item, default)
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
      # The method assumes that :articles is the only lens that handles items
      # of type EdsDocument.
      #
      def key_for_doc(doc, default = true)
        if doc.respond_to?(:lens) && doc.lens
          doc.lens
        elsif doc
          doc_id = doc.respond_to?(:id) ? doc.id : doc.to_s
          doc_id.include?('__') ? :articles : :catalog
        elsif default.is_a?(TrueClass)
          default_lens_key
        elsif !default.is_a?(FalseClass)
          default
        end
      end

      # Translate a named item to a lens key.
      #
      # If the name is derived from the current controller then the method will
      # attempt to strip off name variations to find the core name (for example,
      # 'video_advanced' will result in 'video'; 'articles_suggest' will result
      # in 'articles', etc).
      #
      # @param [String, Symbol, Class, Entry, Blacklight::Controller] name
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
          default_lens_key
        elsif !default.is_a?(FalseClass)
          default
        end
      end

      # Return the lens key for the related controller which is used for the
      # canonical version of paths that are generated through the controller
      # associated with *lens_key*.
      #
      # @param [Symbol] lens_key
      #
      # @return [Symbol]
      #
      # TODO: This information should come from Config::Base and derivatives.
      #
      def canonical_for(lens_key)
        lens_key = key_for(lens_key)
        (lens_key == :articles) ? lens_key : default_lens_key
      end

    end

  end

end

__loading_end(__FILE__)
