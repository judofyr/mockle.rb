require_relative 'helper'
require 'mockle/parser'

module Mockle
  class TestParser < MiniTest::Unit::TestCase
    def setup
      @parser = Parser.new
    end

    def s(*args)
      @parser.s(*args)
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
        s(:contents,
          s(:html, 'Hello '),
          s(:text, s(:lookup, 'world', nil)),
          s(:html, '!')),
        %q{Hello @world!})
    end
  end
end

