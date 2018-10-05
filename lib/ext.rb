# lib/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# This file is loaded from config/initializers/_extensions.rb.

require_relative '_trace' # Loader debugging.

# =============================================================================
# Constants
# =============================================================================

public

# Control prepending of override definitions from 'lib/ext/*/*.rb'.
#
# During normal operation this should be set to *true*.  Change the default
# value here or override dynamically with the environment variable.
#
# NOTE: setting to *false* should be for experimentation only since it will
# result in untested execution paths.
#
IMPLEMENT_OVERRIDES = env('IMPLEMENT_OVERRIDES', true)

# This constant is defined to mark sections of code that are present only to
# give context information to RubyMine -- for example, "include" statements
# which allow RubyMine to indicate which methods are overrides.
#
# (This constant is required to be a non-false value.)
#
ONLY_FOR_DOCUMENTATION = true

# =============================================================================
# Overrides
# =============================================================================

if IMPLEMENT_OVERRIDES

  # This method can be used as a simple mechanism to override member(s) of a
  # class or module by supplying new methods or redefinitions of existing
  # methods within a block that is prepended as an anonymous module.
  #
  # @param [Class] mod                The class or module to override
  #
  # @yield
  #
  # @return [void]
  #
  # == Usage Notes
  # Within the block given, define new methods that *mod* will respond to
  # and/or redefine existing methods.  Within redefined methods, "super" refers
  # to the original method.
  #
  def override(mod, &block)
    unless block
      message = "Override of #{mod} failed - no definition block supplied"
      if Rails.env.production?
        Rails.logger.error(message)
      else
        raise message
      end
    end
    mod.send(:prepend, Module.new(&block))
  end

else

  Log.warn("IMPLEMENT_OVERRIDES = #{IMPLEMENT_OVERRIDES.inspect}")

  def override(mod, &block)
    Rails.logger.warn("Override of #{mod} suppressed by configuration.")
    # Nothing in *block* will be executed.
  end

end

# =============================================================================
# Require all modules from the "lib/ext" directory
# =============================================================================

__loading_begin(__FILE__)

_LIB_EXT_LOADS ||=
  begin
    libext = File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'))

    # Kernel definition overrides.
    Dir[File.join(libext, '*.rb')].each { |path| require(path) }

    # Overrides must be brought in so that dependent classes/modules are
    # overridden after overrides of any classes/modules on which they depend:
    # - 'ext/blacklight' comes before other gem overrides
    # - Within a gem override, 'ext/GEM/lib' comes before 'ext/GEM/app'
    # - Within 'ext/GEM/app', 'helpers' comes before 'controllers'
    # For the moment, these can be satisfied by requiring the paths in reverse
    # order of full path length.
    Dir[File.join(libext, '**', '*.rb')]
      .sort_by { |path| path.size }
      .each { |path| require(path) }
  end

__loading_end(__FILE__)
