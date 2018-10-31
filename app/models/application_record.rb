# app/models/application_record.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

class ApplicationRecord < ActiveRecord::Base
  self.abstract_class = true
end

__loading_end(__FILE__)
