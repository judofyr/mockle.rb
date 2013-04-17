require_relative 'helper'
require 'json'
require 'mockle/template'

module Mockle
  class TestSpec < MiniTest::Unit::TestCase
    SPEC_DIR = File.expand_path('../spec/specs', __FILE__)
    Dir.glob(SPEC_DIR + '/*.json') do |file|
      spec = JSON.parse(File.read(file))
      spec['tests'].each do |test|
        define_method("test: #{test['name']}") do
          tmpl = Template.new(test['template'])
          res = tmpl.render(test['data'])
          assert_equal test['expected'], res
        end
      end
    end
  end
end

