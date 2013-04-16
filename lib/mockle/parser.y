class Mockle::Parser

token TEXT ATCHAR IDENT DOT NUMBER IF LPAREN RPAREN ELSE FOR ENDFOR ENDIF ELSEIF IN CALL CNAME COMMA EQ

rule
  main
    : contents

  contents
    : content
    | contents content
        {
          result = if val[0].type == :multi
            val[0].append(val[1])
          else
            s(:multi, val[0], val[1], val[0].lineno)
          end
        }

  content
    : TEXT    { result = s(:html, value(val[0]), lineno(val[0])) }
    | ATCHAR  { result = s(:html, value(val[0]), lineno(val[0])) }
    | expr    { result = s(:text, val[0], val[0].lineno) }
    | if   
    | for  
    | call 

  expr
    : IDENT
        { result = s(:lookup, value(val[0]), nil, lineno(val[0])) }
    | expr DOT IDENT
        { result = s(:lookup, value(val[2]), val[0], lineno(val[1])) }
    | NUMBER
        { result = s(:number, value(val[0]), lineno(val[0])) }

  if
    : IF LPAREN expr RPAREN contents if_end
        { result = s(:if, val[2], val[4], val[5], lineno(val[0])) }

  else
    : ELSE contents { result = val[1] }
    | ELSE LPAREN RPAREN contents { result = val[3] }

  if_end
    : ENDIF { result = nil }
    | else ENDIF
    | ELSEIF LPAREN expr RPAREN contents if_end
        { result = s(:if, val[2], val[4], val[5], lineno(val[0])) }

  for
    : FOR LPAREN IDENT IN expr RPAREN contents for_end
        { result = s(:for, val[2], val[4], val[6], val[7], lineno(val[0])) }

  for_end
    : ENDFOR { result = nil }
    | else ENDFOR

  call
    : CALL LPAREN CNAME arglist RPAREN
        { result = s(:call, val[2], val[3], lineno(val[0])) }
    | CALL LPAREN CNAME RPAREN
        { result = s(:call, val[2], [], lineno(val[0])) }

  arg
    : COMMA expr { result = s(:argsplat, val[1], val[1].lineno) }
    | COMMA IDENT EQ expr { result = s(:arg, value(val[1]), val[3], lineno(val[1])) }

  arglist
    : arg         { result = val[0] }
    | arglist arg { result = val[0] << val[1] }

---- header
  require 'mockle/lexer'
  require 'mockle/node'

---- inner
  def initialize(options = {})
    super()
  end

  def s(type, *children, lineno)
    Mockle::Node.new(type, children, :lineno => lineno)
  end

  def value(token)
    token[0]
  end

  def lineno(token)
    token[1]
  end

  def parse(str)
    @lexer = Lexer.new(str)
    do_parse
  end

  def next_token
    @lexer.next_token
  end

  def on_error(t, val, vstack)
    p @lexer
    super
  end
  
