require_relative 'error'

module Cumuliform
  module Functions
    def ref(logical_id)
      {"Ref" => xref(logical_id)}
    end

    def xref(logical_id)
      unless has_logical_id?(logical_id)
        raise Error::NoSuchLogicalId, logical_id
      end
      logical_id
    end
  end
end
