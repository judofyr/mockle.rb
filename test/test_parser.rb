require_relative 'helper'
require 'mockle/parser'

module Mockle
  class TestParser < MiniTest::Unit::TestCase
    def setup
      @parser = Parser.new
    end

    def s(*args)
      @parser.s(*args, 1)
    end

    def assert_parses(exp, str)
      assert_equal exp, @parser.parse(str)
    end

    def test_text
      assert_parses(
        s(:html, 'Hello world!'),
        %q{Hello world!})
    end

    def test_if
      assert_parses(
        s(:if, s(:lookup, 'a', nil),
         s(:html, 'nice'), nil),
        %q{@if(a)nice@endif})
    end

    def test_variables
      assert_parses(
        s(:multi,
          s(:html, 'Hello '),
          s(:text, s(:lookup, 'world', nil)),
          s(:html, '!')),
        %q{Hello @world!})
    end

    def test_linenumbers
      ast = @parser.parse("Hello\n@world")
      assert_equal 1, ast.lineno
      txt1, txt2, var = *ast

      assert_equal s(:html, "Hello"), txt1
      assert_equal 1, txt1.lineno

      assert_equal s(:html, "\n"), txt2
      assert_equal 1, txt2.lineno

      assert_equal s(:text, s(:lookup, 'world', nil)), var
      assert_equal 2, var.lineno
    end
  end
end

