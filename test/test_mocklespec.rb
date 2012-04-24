require 'helper'
require 'mockle/engine'
require 'json'

module Mockle
  class TestSpec < TestCase
    SPECS = File.expand_path('../mockle.spec/specs/*.json', __FILE__)
    Dir[SPECS].each do |spec_file|
      spec = JSON.parse(File.read(spec_file))
      spec["tests"].each do |test|
        define_method("test: #{test["name"]}") do
          ctx = {}
          test["data"].each do |key, value|
            ctx[key.to_sym] = value
          end
          res = execute(test["template"], ctx)
          assert_equal test["expected"], res
        end
      end
    end

    def execute(str, ctx = {})
      engine = Engine.new
      code = engine.call(str)
      eval(code)
    end
  end
end

