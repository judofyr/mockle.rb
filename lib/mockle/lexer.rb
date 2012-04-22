require 'strscan'

module Mockle
  class Lexer
    def initialize(str)
      @ss = StringScanner.new(str)
      @state = :text
      @level = 0
    end

    def next_token
      return if @ss.eos?
      send("scan_#{@state}")
    end

    def scan_text
      # If we're at the beginning of a line we first try to parse space + @
      text = @ss.beginning_of_line? && @ss.scan(/[ \t]*@/)
      # If that failed we want to parse until we find a @ (possibly with space at
      # the beginning of the line).
      text ||= @ss.scan_until(/(\n[ \t]*)?@/)

      if text
        matched = @ss.matched.size
        matched -= 1 if text[-matched] == ?\n
        @ss.pos -= matched
        text.slice!(-matched..-1)
        @state = :space
      else
        text = @ss.rest
        @ss.terminate
      end

      if text.empty?
        next_token
      else
        [:TEXT, text]
      end
    end

    SYMBOLS = {
      "+" => :ADD,
      "-" => :SUB,
      "*" => :MUL,
      "/" => :DIV,
      "%" => :MOD,
      "=" => :ASSIGN,
      "!" => :BANG
    }

    CMP = %w[== != > < >= <=]

    SYMRE = Regexp.union(CMP + SYMBOLS.keys)
    SPACE_SYMRE = /\s*(#{SYMRE})\s*/

    KEYWORDS = /(#{Regexp.union(%w[if else elseif for end])})\b/

    def scan_expr
      case
      when @ss.scan(/@@/)
        @state = :text
        [:TEXT, "@"]

      when @ss.scan(/@/)
        [:START, "@"]

      when @ss.scan(/\./)
        [:DOT, "."]

      when @ss.scan(/\$/)
        [:DOLLAR, "$"]

      when @ss.scan(/\(/)
        @level += 1
        [:LPAREN, "("]

      when text = @ss.scan(KEYWORDS)
        [text.strip.upcase.to_sym, text]

      when text = @ss.scan(/\d+/)
        [:NUM, text]

      when text = @ss.scan(/\w+/)
        [:IDENT, text]

      when @level > 0
        scan_inner

      else
        @state = :newline
        next_token
      end
    end

    def scan_inner
      case
      when text = @ss.scan(/\s*in\s*\b/)
        [:IN, text]

      when sym = @ss.scan(SPACE_SYMRE)
        [SYMBOLS[sym.strip] || :CMP, sym]
      when @ss.scan(/\)/)
        @level -= 1
        @state = :newline if @level.zero?
        [:RPAREN, ")"]

      when delim = @ss.scan(/["']/)
        stop = @ss.scan_until(/#{delim}/)
        stop.slice!(-1)
        [:STRING, stop]

      when text = @ss.scan(/\s+/)
        [:INNERSPACE, text]

      else
        raise "Oops"
      end
    end

    def scan_newline
      @state = :text
      if text = @ss.scan(/\n/)
        [:NEWLINE, text]
      else
        next_token
      end
    end

    def scan_space
      @state = :expr
      if text = @ss.scan(/\s+/)
        [:SPACE, text]
      else
        next_token
      end
    end
  end
end

