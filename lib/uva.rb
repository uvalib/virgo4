# lib/uva.rb
#
# frozen_string_literal: true
# warn_indent:           true

require '_trace'

__loading_begin(__FILE__)

# =============================================================================
# Utility methods
# =============================================================================

# Require files via one or more "glob" patterns.
#
# @param [String] relative_to         Normally supplied as __FILE__
# @param [Array<String>] patterns     One or more relative paths; each path may
#                                       include "glob" patterns to specify
#                                       multiple files.
#
# @return [void]
#
# @see Dir#glob
#
def require_files(relative_to, *patterns)
  dir = File.dirname(relative_to)
  patterns.flatten.reject(&:blank?).uniq.flat_map do |pattern|
    Dir.glob("#{dir}/#{pattern}")
      .reject  { |path| (path == relative_to) || (path == dir) }
      .sort_by { |path| [path, path.length] }
      .each    { |path| require path }
  end
end

# Require subdirectories via one or more "glob" patterns.
#
# @param [String] relative_to         Normally supplied as __FILE__
# @param [Array<String>] patterns     One or more relative paths; each path may
#                                       include "glob" patterns to specify
#                                       multiple files.
#
# @return [void]
#
# @see Dir#glob
#
def require_subdir(relative_to, *patterns)
  subdirs = patterns.flatten.reject(&:blank?).uniq
  subdirs << '' if subdirs.blank?
  subdirs.map! { |subdir| "#{subdir}/**/*.rb" }
  require_files(relative_to, subdirs)
end

# =============================================================================
# Modules outside of the Blacklight namespace.
# =============================================================================

module UVA
end
include UVA

# =============================================================================
# Require all modules from the "lib/uva" directory
# =============================================================================

require 'ext/active_support/ext'
require_subdir(__FILE__, 'uva')
require 'ext'
require 'blacklight/lens'
require_subdir(__FILE__, 'blacklight/solr')
require 'blacklight/eds'

__loading_end(__FILE__)
