require 'temple'
require 'set'

module Mockle
  class Compiler < Temple::Filter
    def initialize(options = {})
    end

    def on_mockle_block(exp)
      @lvars = Set.new
      @gvars = Set.new

      inner = compile(exp)
      lvars = @lvars.map { |x| "_var_#{x}=" }.join
      [:multi,
        [:code, "#{lvars} 0 if false"],
        inner]
    end

    def on_mockle_output(exp)
      [:dynamic, compile(exp)]
    end

    def on_mockle_var(name)
      @lvars << name
      "_var_#{name}"
    end

    def on_mockle_lctx(name)
      @gvars << name
      "ctx[#{name.to_sym.inspect}]"
    end

    def on_mockle_ctx(name)
      on_mockle_lctx(name)
    end

    def on_mockle_dot(exp, name)
      type = exp[1]
      base = "base = #{compile(exp)};"

      case name
      when String # foo.bar
        str = name.inspect
        lit = name.to_sym.inspect
        call = name
      when Fixnum # foo.0
        lit = name
        str = name.to_s.inspect
      when Array # foo.(bar)
        base = "lit=#{compile(name)};" + base
        lit = "lit"
        str = "lit.to_s"
        call = "send(#{str})"
      end

      array_pre_check = "#{lit}.respond_to?(:to_int)"
      array_check = "base.is_a?(Array)"
      array_run = "base[#{lit}]"

      hash_check = "base.is_a?(Hash)"
      hash_run = "base.fetch(#{lit}) { base[#{str}] }"

      method_check = "base.respond_to?(#{lit})"
      method_run = "base.#{call}"

      "(#{base}"\
        "#{hash_check} ? #{hash_run} : "\
        "(#{array_pre_check} && #{array_check}) ? #{array_run} : "\
        "(#{method_run} if #{method_check})"\
      ")"
    end

    def on_mockle_if(cond, true_branch, false_branch)
      [:if, compile(cond), compile(true_branch), (compile(false_branch) if false_branch)]
    end

    def on_mockle_for(var, collection, code)
      reset(var)
      [:multi,
        [:code, "#{compile(collection)}.each do |e| #{compile(var)}=e"],
        compile(code),
        [:code, "end"]]
    end

    def on_mockle_assign(var, expr)
      reset(var)
      [:code, "#{compile(var)} = #{compile(expr)}"]
    end

    def on_mockle_capture(var, expr)
      reset(var)
      [:multi,
        [:capture, "_cap", compile(expr)],
        [:code, "(#{compile(var)} ||= '') << _cap"]]
    end

    def on_mockle_num(n)
      n.to_i
    end

    def on_mockle_op(name, a, b)
      "(#{compile(a)} #{name} #{compile(b)})"
    end

    def reset(var)
      # TODO: Implement funky fast stuff!
    end
  end
end

