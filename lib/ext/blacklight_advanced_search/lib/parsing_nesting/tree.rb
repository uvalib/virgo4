# lib/ext/blacklight_advanced_search/lib/parsing_nesting/tree.rb
#
# Inject ParsingNesting::Tree::Node extensions and replacement methods.

__loading_begin(__FILE__)

require 'parsing_nesting/tree'

module ParsingNesting::Tree

  module NodeExt

    # build_local_params
    #
    # @param [Hash, nil]   hash
    # @param [String, nil] def_type   Set to *nil* if "!dismax" should not be
    #                                   embedded in the result.
    #
    # @return [String]
    #
    # This method overrides:
    # @see ParsingNesting::Tree::Node#build_local_params
    #
    # == Implementation Notes
    # This method is overridden to ensure that :qf and :pf are single-quoted as
    # our Solr expects.
    #
    def build_local_params(hash = {}, def_type = 'dismax')
      return '' if hash.blank?
      def_type ||= hash['defType'] || hash[:defType]
      result = +'{!'
      result << def_type << ' ' if def_type.present?
      result <<
        hash.map { |k, v|
          next if (k = k.to_s.strip).blank? || (k == 'defType')
          next if (v = v.to_s.strip).blank?
          case v
            when /^'(.*)'$/ then # already single-quoted
            when /^"(.*)"$/ then v = %Q('#{$1}')
            when /^.*\s.*$/ then v = %Q('#{v}')
            else                 v = %Q('#{v}') if %w(pf qf).include?(k)
          end
          "#{k}=#{v}"
        }.compact.join(' ')
      result << '}'
    end

  end

end

# =============================================================================
# Override gem definitions
# =============================================================================

override ParsingNesting::Tree::Node => ParsingNesting::Tree::NodeExt

__loading_end(__FILE__)
