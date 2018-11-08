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
