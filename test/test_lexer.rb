require_relative 'helper'
require 'mockle/lexer'

module Mockle
  class TestLexer < MiniTest::Unit::TestCase
    def assert_lexes(str, tokens)
      res = []
      lexer = Lexer.new(str)
      while token = lexer.next_token
        res << token
      end
      assert_equal tokens, res
    end

    def test_text
      assert_lexes 'Hello world',
        [[:TEXT, 'Hello world']]
    end

    def test_atchar
      assert_lexes 'email@@host',
        [[:TEXT, 'email'], [:ATCHAR, '@@'], [:TEXT, 'host']]
    end

    def test_variable
      assert_lexes 'Hello @person.name!', [
        [:TEXT, 'Hello '],
        [:IDENT, 'person'],
        [:DOT, '.'],
        [:IDENT, 'name'],
        [:TEXT, '!'],
      ]
    end

    def test_call
      assert_lexes 'Hello @call(a/b/c.html, a=1)', [
        [:TEXT, 'Hello '],
        [:CALL, 'call'],
        [:LPAREN, '('],
        [:CNAME, 'a/b/c.html'],
        [:COMMA, ','],
        [:IDENT, 'a'],
        [:EQ, '='],
        [:NUMBER, '1'],
        [:RPAREN, ')'],
      ]
    end

    def test_for
      assert_lexes '@for(a in b)t@endfor()', [
        [:FOR, 'for'],
        [:LPAREN, '('],
        [:IDENT, 'a'],
        [:IN, ' in '],
        [:IDENT, 'b'],
        [:RPAREN, ')'],
        [:TEXT, 't'],
        [:ENDFOR, 'endfor'],
        [:LPAREN, '('],
        [:RPAREN, ')'],
      ]
    end
  end
end

