# app/models/concerns/ils/record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/schema'

# Namespace for objects defined by the ILS Connector API.
#
module Ils::Record
end

require_subdir(__FILE__)

__loading_end(__FILE__)
