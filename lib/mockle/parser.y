class Mockle::Parser

token TEXT START LPAREN RPAREN STRING NUM IDENT DOT ADD SUB MUL DIV MOD SPACE DOLLAR ASSIGN CMP IF END FOR IN BANG ELSE ELSEIF NEWLINE INNERSPACE

prechigh
  left DOT
  nonassoc NOT
  left MUL DIV MOD
  left ADD SUB
  left INNERSPACE
  left CMP
  left ASSIGN
preclow

rule
  program
    : program content { result = combine(val[0], val[1]) }
    | content

  content
    : text
    | START expression { result = [:mockle, :output, val[1]] }
    | START expression NEWLINE
      { result = [:multi, [:mockle, :output, val[1]], [:static, val[2]]] }
    | START statement { result = val[1] }
    | SPACE START statement { result = val[2] }

  stmt_start
    : START
    | SPACE START

  opt_newline
    :
    | NEWLINE

  statement
    : LPAREN assignment RPAREN opt_newline { result = val[1] }
    | IF LPAREN expression RPAREN opt_newline program ifclose
      { result = [:mockle, :if, val[2], val[5], val[6]] }
    | FOR LPAREN local_ident IN expression RPAREN opt_newline program end_block
      {
        result = [:mockle, :for, val[2], val[4], val[7]]
      }

  assignment
    : local_ident ASSIGN expression
      { result = [:mockle, :assign, val[0], val[2]] }
    | DOLLAR IDENT ASSIGN expression
      { result = [:mockle, :assign, [:mockle, :lctx, val[1]], val[3]] }

  ifclose
    : stmt_start ELSEIF LPAREN expression RPAREN opt_newline program ifclose
      { result = [:mockle, :if, val[3], val[6], val[7]] }
    | stmt_start ELSE opt_parens opt_newline program end_block
      { result = val[4] }
    | end_block { result = nil }

  opt_parens
    :
    | LPAREN RPAREN

  local_ident
    : IDENT
      {
        @locals[val[0]] = true
        result = [:mockle, :var, val[0]]
      }

  end_block
    : stmt_start END opt_newline
  
  text
    : TEXT { result = [:static, val.first] }

  expression
    : group
    | variable
    | number
    | expression ADD expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | expression SUB expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | expression MUL expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | expression DIV expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | expression MOD expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | expression INNERSPACE expression { result = [:mockle, :concat, val[0], val[2]] }
    | expression CMP expression { result = [:mockle, :op, val[1], val[0], val[2]] }
    | BANG expression =NOT  { result = [:mockle, :not, val[1]] }

  group
    : LPAREN expression RPAREN { result = val[1] }

  variable
    : IDENT { result = [:mockle, @locals[val[0]] ? :var : :ctx, val[0]] }
    | DOLLAR IDENT { result = [:mockle, :ctx, val[1]] }
    | variable DOT IDENT { result = [:mockle, :dot, val[0], val[2]] }
    | variable DOT NUM   { result = [:mockle, :dot, val[0], val[2].to_i] }
    | variable DOT group { result = [:mockle, :dot, val[0], val[2]] }

  number
    : NUM { result = [:mockle, :num, val.first] }

---- header
  require 'mockle/lexer'

---- inner
  def initialize(options = {})
    super()
  end

  def parse(str)
    @locals = {}
    @lexer = Lexer.new(str)
    [:mockle, :block, do_parse]
  end
  
  alias call parse
  
  def next_token
    @lexer.next_token
  end

  def on_error(*a)
    p a
    p @lexer
    super
  end
  
  def combine(a, b)
    a = [:multi, a] unless a[0] == :multi
    if b[0] == :multi
      a.concat(b[1..-1])
    else
      a << b
    end
  end
