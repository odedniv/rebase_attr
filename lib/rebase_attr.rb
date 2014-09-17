require "rebase_attr/version"

module RebaseAttr
  module Generator
    def rebase_attr(*attributes, to: nil, from: nil, convert: nil, readable: nil)
    end
  end
end

class Module
  include RebaseAttr::Generator
end
