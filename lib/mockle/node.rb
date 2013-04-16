require 'ast'

module Mockle
  class Node < ::AST::Node
    attr_reader :lineno

    def value
      children[0]
    end
  end
end

