# lib/ext/blacklight/ext.rb
#
# frozen_string_literal: true
# warn_indent:           true
#
# Extensions for the Blacklight gem.

__loading_begin(__FILE__)

require 'blacklight'

# Hook up logger.
Log ||= Blacklight.logger

# Load search repository definitions from blacklight.yml.
#
# Unlike the original Blacklight method, this allows the use of YAML aliases.
#
# @return [Hash]
#
# This method overrides:
# @see Blacklight#blacklight_yml
#
# == Implementation Note
# Defining a module to prepend to Blacklight could not successfully cause the
# definition of `self.blacklight_yml` to be overridden in time.  This explicit
# definition was the only way to redefine the function early enough for the
# files internal to the Blacklight gem to pick up the definition during
# loading.
#
def Blacklight.blacklight_yml
  @blacklight_yml ||=
    begin
      require 'erb'
      require 'yaml'
      result = msg = err = nil
      cfg    = blacklight_config_file
      txt    = IO.read(cfg)
      erb    = ERB.new(txt).result(binding)
      result = YAML.safe_load(erb, [], [], true)
    rescue Errno::ENOENT
      msg = "You are missing a configuration file: #{cfg}."
      err = 'Have you run "rails generate blacklight:install"?'
    rescue StandardError, SyntaxError => e
      msg = "#{cfg} was found, but could not be parsed with ERB."
      err = e.inspect
    rescue => e
      msg = "#{cfg} was found, but could not be parsed."
      err = e.inspect
    ensure
      if result.present?
        result
      elsif msg.present?
        raise "#{msg}\n#{err}"
      end
    end
end

# As of Blacklight 7, Blacklight::BlacklightHelperBehavior and
# Blacklight::CatalogHelperBehavior require modules that are not specified by
# a full namespace.  Because of the way that the gem overrides are occuring,
# this becomes a problem because they appear to be modules which are *relative*
# to the including module rather than relative to the "Blacklight" namespace.
#
# Providing empty definitions here prevents this from being a problem.

module UrlHelperBehavior                       end # :nodoc:
module HashAsHiddenFieldsHelperBehavior        end # :nodoc:
module LayoutHelperBehavior                    end # :nodoc:
module IconHelperBehavior                      end # :nodoc:
module ConfigurationHelperBehavior             end # :nodoc:
module ComponentHelperBehavior                 end # :nodoc:
module FacetsHelperBehavior                    end # :nodoc:
module RenderConstraintsHelperBehavior         end # :nodoc:
module RenderPartialsHelperBehavior            end # :nodoc:
module SearchHistoryConstraintsHelperBehavior  end # :nodoc:
module SuggestHelperBehavior                   end # :nodoc:

# Require all files from this directory.
require_subdir(__FILE__)

__loading_end(__FILE__)
