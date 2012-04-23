require 'temple'
require 'set'

module Mockle
  class Compiler < Temple::Filter
    def initialize(options = {})
    end

    def on_mockle_block(exp)
      @lvars = Set.new

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
      if @lvars.include?(name)
        "_var_#{name}"
      else
        on_mockle_ctx(name)
      end
    end

    def on_mockle_ctx(name)
      "ctx[#{name.to_sym.inspect}]"
    end

    def on_mockle_dot(exp, name)
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

    def on_mockle_call(base, name, args)
      arg = args.map { |x| compile(x) }.join(', ')
      "base=#{compile(base)};(base.#{name}(#{arg}) if base.respond_to?(#{name.to_sym.inspect}))"
    end

    def on_mockle_partial(name, args)
      res = [:multi]

      ctx      = args.keys.map { |x| on_mockle_ctx(x) }.join(", ")
      preserve = args.keys.map { |x| "_partial_#{x}"  }.join(", ")
      values = args.values.map { |x| compile(x)       }.join(", ")

      if !args.empty?
        res << [:code, "#{preserve} = #{ctx}"]
        res << [:code, "#{ctx} = #{values}"]
      end

      res << [:dynamic, "render_partial(#{name.inspect}, ctx)"]
      res << [:code, "#{ctx} = #{preserve}"] if !args.empty?

      res
    end

    def on_mockle_if(cond, true_branch, false_branch)
      [:if, compile(cond), compile(true_branch), (compile(false_branch) if false_branch)]
    end

    def on_mockle_for(var, collection, code)
      assign(var)
      [:multi,
        [:code, "#{compile(collection)}.each do |e| #{compile(var)}=e"],
        compile(code),
        [:code, "end"]]
    end

    def on_mockle_assign(var, expr)
      assign(var)
      [:code, "#{compile(var)} = #{compile(expr)}"]
    end

    def on_mockle_capture(var, expr)
      assign(var)
      [:multi,
        [:capture, "_cap", compile(expr)],
        [:code, "(#{compile(var)} ||= '') << _cap"]]
    end

    def on_mockle_op(name, a, b)
      "(#{compile(a)} #{name} #{compile(b)})"
    end

    def on_mockle_concat(a, b)
      '"#{%s}#{%s}"' % [compile(a), compile(b)]
    end

    def on_mockle_num(n)
      n.to_i
    end

    def on_mockle_str(n)
      n.inspect
    end

    def assign(var)
      case var[1]
      when :var
        @lvars << var[2]
      when :ctx
      else
        raise "Cannot assign: #{var.inspect}"
      end
    end
  end
end

