class Mockle::Parser

token TEXT ATCHAR IDENT DOT NUMBER IF LPAREN RPAREN ELSE FOR ENDFOR ENDIF ELSEIF IN CALL CNAME COMMA EQ

rule
  main
    : contents

  contents
    : content
    | contents content
        {
          result = if val[0].type == :contents
            val[0].append(val[1])
          else
            s(:contents, val[0], val[1])
          end
        }

  content
    : TEXT    { result = s(:html, val[0]) }
    | ATCHAR  { result = s(:html, val[0]) }
    | expr    { result = s(:text, val[0]) }
    | if   
    | for  
    | call 

  expr
    : IDENT
        { result = s(:lookup, val[0], nil) }
    | expr DOT IDENT
        { result = s(:lookup, val[2], val[0]) }
    | NUMBER
        { result = s(:number, val[0]) }

  if
    : IF LPAREN expr RPAREN contents if_end
        { result = s(:if, val[2], val[4], val[5]) }

  else
    : ELSE contents { result = val[1] }
    | ELSE LPAREN RPAREN contents { result = val[3] }

  if_end
    : ENDIF { result = nil }
    | else ENDIF
    | ELSEIF LPAREN expr RPAREN contents if_end
        { result = s(:if, val[2], val[4], val[5]) }

  for
    : FOR LPAREN IDENT IN expr RPAREN contents for_end
        { result = s(:for, val[2], val[4], val[6], val[7]) }

  for_end
    : ENDFOR { result = nil }
    | else ENDFOR

  call
    : CALL LPAREN CNAME arglist RPAREN
        { result = s(:call, val[2], val[3]) }
    | CALL LPAREN CNAME RPAREN
        { result = s(:call, val[2], []) }

  arg
    : COMMA expr { result = s(:argsplat, val[1]) }
    | COMMA IDENT EQ expr { result = s(:arg, val[1], val[3]) }

  arglist
    : arg         { result = val[0] }
    | arglist arg { result = val[0] << val[1] }

---- header
  require 'mockle/lexer'
  require 'ast'

---- inner
  def initialize(options = {})
    super()
  end

  def parse(str)
    @lexer = Lexer.new(str)
    do_parse
  end
  
  alias call parse

  def s(type, *children)
    AST::Node.new(type, children)
  end
  
  def next_token
    @lexer.next_token
  end

  def on_error(t, val, vstack)
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
