require 'ast'

module Mockle
  class Node < ::AST::Node
    attr_reader :lineno

    def value
      children[0]
    end

    def on_line(no)
      updated(nil, nil, :lineno => no)
    end
  end
end

