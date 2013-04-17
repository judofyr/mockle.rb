require 'ast'

module Mockle
  class Backend < AST::Processor
    def initialize
      @lineno = 1
      @state = :ruby
    end

    def compile(node)
      res = ""
      each_flatten(node) do |n|
        newlines = n.lineno - @lineno
        @lineno = n.lineno

        case @state
        when :ruby
          res << "\n" * newlines
        when :string
          res << "\"\\\n\"" * newlines
        end

        res << process(n)
      end
      res << finalize
    end

    def finalize
      case @state
      when :ruby
        ""
      when :string
        @state = :ruby
        '"'
      end
    end

    def each_flatten(node, &blk)
      if node.type != :multi
        yield node
        return
      end

      node.children.each do |n|
        each_flatten(n, &blk)
      end
    end

    def on_statement(node)
      finalize + ";#{node.value};"
    end

    def append(code)
      case @state
      when :ruby
        @state = :string
        ';_buf << "' + code
      when :string
        code
      end
    end
    
    def on_expression(node)
      append('#{%s}' % node.value)
    end

    def on_text(node)
      append(node.value.inspect[1..-2])
    end
  end
end

