# lib/uva.rb
#
# frozen_string_literal: true
# warn_indent:           true

__loading_begin(__FILE__)

# Modules outside of the Blacklight namespace.
module UVA
end
include UVA

# Require all modules from the "lib/uva" directory.
_LIB_UVA_LOADS ||=
  begin
    dir = File.join(File.dirname(__FILE__), File.basename(__FILE__, '.rb'))
    Dir[File.join(dir, '**', '*.rb')].each { |path| require(path) }
  end

__loading_end(__FILE__)
