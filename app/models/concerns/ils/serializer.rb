# app/models/concerns/ils/serializer.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

require 'ils/schema'

# Namespace for the serialization/de-serialization mechanisms associated with
# objects derived from Ils::Record::Base.
#
module Ils::Serializer
end

require_subdir(__FILE__)

__loading_end(__FILE__)
