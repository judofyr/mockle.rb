require 'mockle/node'

module Mockle
  class Compiler < AST::Processor
    def initialize
      @lineno = 1
    end

    def process(node)
      node = node.to_ast
      @lineno = node.lineno
      send(:"on_#{node.type}", node)
    end

    def s(type, *children)
      Node.new(type, children, :lineno => @lineno)
    end

    def on_multi(node)
      node.updated(:multi, process_all(node))
    end

    def on_html(node)
      s(:text, node.to_a[0])
    end

    def on_if(node)
      cond, tbranch, fbranch = *node
      s(:multi,
        s(:statement, "if #{compile_cond(cond)}"),
        process(tbranch),
        s(:statement, "else"),
        process(fbranch || s(:multi)),
        s(:statement, "end"))
    end

    def on_text(node)
      s(:expression, process(node.to_a[0]))
    end

    ## Expressions

    def on_lookup(node)
      name, base = *node
      if base
        compile_lookup(process(base), name)
      else
        "data[#{name.inspect}]"
      end
    end

    def compile_lookup(base, name)
      "(_base = #{base};"+
      "_base.respond_to?(:[]) ? "+
      "_base[#{name.to_sym.inspect}] : "+
      "_base.#{name})"
    end

    def compile_cond(cond)
      "(cond = #{process(cond)}) && "+
      "!(cond.respond_to?(:empty?) && cond.empty?) && "+
      "!(cond.respond_to?(:zero?) && cond.zero?)"
    end

    def handler_missing(node)
      raise "Missing handler for #{node.type}"
    end
  end
end

