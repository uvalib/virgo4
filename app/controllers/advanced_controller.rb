# app/controllers/advanced_controller.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# AdvancedController
#
# @see CatalogAdvancedController
#
# == Usage Notes
# Nothing should currently be using this controller; the "/advanced" route is
# an "alias" for "/catalog/advanced".  However, this controller might be useful
# in the future for "combined search" (a.k.a "Catalog+Articles" search).
#
class AdvancedController < CatalogAdvancedController
end

__loading_end(__FILE__)
