require_relative 'helper'
require 'mockle/backend'
require 'mockle/node'

module Mockle
  class TestBackend < MiniTest::Unit::TestCase
    def setup
      @backend = Backend.new
    end

    def s(type, *children)
      Mockle::Node.new(type, children, :lineno => 1)
    end

    def eval_ast(ast)
      _buf = []
      eval(@backend.compile(ast))
      _buf
    end

    def assert_compiles(ast, exp)
      assert_equal exp, eval_ast(ast)
    end

    def test_text
      assert_compiles(
        s(:text, 'Hello world!'),
        ['Hello world!'])
    end

    def test_expression
      @world = 'world'
      assert_compiles(
        s(:multi,
          s(:text, 'Hello '),
          s(:expression, '@world'),
          s(:text, '!')),
        ['Hello world!'])
    end

    def test_statement
      @world = 'world'
      assert_compiles(
        s(:multi,
          s(:statement, 'world = @world'),
          s(:text, 'Hello '),
          s(:expression, 'world'),
          s(:text, '!')),
        ['Hello world!'])
    end

    def test_lineno
      err = assert_raises(RuntimeError) do
        eval_ast(
          s(:multi,
            s(:text, 'Hello'),
            s(:statement, 'raise').on_line(5)))
      end
      assert_match /^\(eval\):5:in/, err.message
    end
  end
end

