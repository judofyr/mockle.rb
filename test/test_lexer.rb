require 'helper'
require 'mockle/lexer'

module Mockle
  class TestLexer < TestCase
    def lex(str)
      @lexer = Lexer.new(str)
    end
    
    def next_token
      @lexer.next_token
    end

    def test_static
      lex "Hello world"
      assert_equal [:TEXT, "Hello world"], next_token
      assert_nil next_token
    end

    def test_literal
      lex "judofyr@@gmail.com"
      assert_equal [:TEXT, "judofyr"], next_token
      assert_equal [:TEXT, "@"], next_token
      assert_equal [:TEXT, "gmail.com"], next_token
      assert_nil next_token
    end

    def test_expr
      lex "Hello @world!"
      assert_equal [:TEXT, "Hello "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:IDENT, "world"], next_token
      assert_equal [:TEXT, "!"], next_token
      assert_nil next_token
    end

    def test_dot
      lex "Hello @user.name!"
      assert_equal [:TEXT, "Hello "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:IDENT, "user"], next_token
      assert_equal [:DOT, "."], next_token
      assert_equal [:IDENT, "name"], next_token
      assert_equal [:TEXT, "!"], next_token
      assert_nil next_token
    end

    def test_paren
      lex "Hello @(user.name)!"
      assert_equal [:TEXT, "Hello "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "user"], next_token
      assert_equal [:DOT, "."], next_token
      assert_equal [:IDENT, "name"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, "!"], next_token
      assert_nil next_token

      lex "Hello @user.(type)!"
      assert_equal [:TEXT, "Hello "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:IDENT, "user"], next_token
      assert_equal [:DOT, "."], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "type"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, "!"], next_token
      assert_nil next_token
    end

    def test_arith
      lex "2 + 2 = @(2 + 2)"
      assert_equal [:TEXT, "2 + 2 = "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:NUM, "2"], next_token
      assert_equal [:ADD, " + "], next_token
      assert_equal [:NUM, "2"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_nil next_token
    end

    def test_string
      lex "Nice @(a 'b')"
      assert_equal [:TEXT, "Nice "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:INNERSPACE, " "], next_token
      assert_equal [:STRING, "b"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_nil next_token
    end

    def test_cmp
      lex "@(a = 1 == 2)"
      assert_equal [:START, "@"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:ASSIGN, " = "], next_token
      assert_equal [:NUM, "1"], next_token
      assert_equal [:CMP, " == "], next_token
      assert_equal [:NUM, "2"], next_token
      assert_equal [:RPAREN, ")"], next_token
    end

    def test_if
      lex "@if(a == b)eq@elseif(b)b@else()else@end"
      assert_equal [:START, "@"], next_token
      assert_equal [:IF, "if"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:CMP, " == "], next_token
      assert_equal [:IDENT, "b"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, "eq"], next_token

      assert_equal [:START, "@"], next_token
      assert_equal [:ELSEIF, "elseif"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "b"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, "b"], next_token

      assert_equal [:START, "@"], next_token
      assert_equal [:ELSE, "else"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, "else"], next_token

      assert_equal [:START, "@"], next_token
      assert_equal [:END, "end"], next_token
      assert_nil next_token
    end

    def test_for
      lex "@for(a in n) hello "
      assert_equal [:START, "@"], next_token
      assert_equal [:FOR, "for"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:IN, " in "], next_token
      assert_equal [:IDENT, "n"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:TEXT, " hello "], next_token
      assert_nil next_token
    end

    def test_bang
      lex "@if(!a)"
      assert_equal [:START, "@"], next_token
      assert_equal [:IF, "if"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:BANG, "!"], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_nil next_token
    end

    def test_whitespace
      lex <<-EOF
@if(hello)
  @for(a in b)
    Nice
  @end
@end
Cool
EOF
      
      assert_equal [:START, "@"], next_token
      assert_equal [:IF, "if"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "hello"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:NEWLINE, "\n"], next_token
      assert_equal [:SPACE, "  "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:FOR, "for"], next_token
      assert_equal [:LPAREN, "("], next_token
      assert_equal [:IDENT, "a"], next_token
      assert_equal [:IN, " in "], next_token
      assert_equal [:IDENT, "b"], next_token
      assert_equal [:RPAREN, ")"], next_token
      assert_equal [:NEWLINE, "\n"], next_token
      assert_equal [:TEXT, "    Nice\n"], next_token
      assert_equal [:SPACE, "  "], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:END, "end"], next_token
      assert_equal [:NEWLINE, "\n"], next_token
      assert_equal [:START, "@"], next_token
      assert_equal [:END, "end"], next_token
      assert_equal [:NEWLINE, "\n"], next_token
      assert_equal [:TEXT, "Cool\n"], next_token
      assert_nil next_token
    end

    def test_failing_partials
      lex "@>>"
      assert_equal [:START, "@"], next_token
      assert_equal [:PARTIAL, ">"], next_token
      assert_equal [:TEXT, ">"], next_token
      assert_nil next_token
    end
  end
end

