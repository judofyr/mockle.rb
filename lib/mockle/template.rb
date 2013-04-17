require 'mockle/parser'
require 'mockle/compiler'
require 'mockle/backend'

module Mockle
  class Template
    def initialize(source)
      @source = source
    end

    def to_ruby
      ast = Parser.new.parse(@source)
      ast = Compiler.new.process(ast)
      code = Backend.new.compile(ast)
    end

    def render(data)
      _buf = []
      eval(to_ruby)
      _buf.join
    end
  end
end


