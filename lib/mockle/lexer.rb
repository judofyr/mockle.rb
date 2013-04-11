require 'strscan'

module Mockle
  class Lexer
    def initialize(source)
      @source = source
      @scanner = StringScanner.new(source)
      @scope = self.class.default_scope
      @scope_stack = []
    end

    def next_token
      return if @scanner.eos?

      self.class.lexers[@scope].each do |match, action|
        if str = @scanner.scan(match)
          res = instance_eval(&action)
          res = [res, str] unless res.is_a?(Array)
          return res
        end
      end

      raise "Can't: #{@scanner.getch}"
    end

    def push(name)
      @scope_stack << @scope
      @scope = name
    end

    def pop
      @scope = @scope_stack.pop
    end

    def less
      @scanner.unscan
    end

    class << self
      attr_accessor :default_scope
    end

    def self.scope(name)
      @default_scope ||= name
      @current_scope = name
      yield
    end

    def self.lexers
      @lexers ||= Hash.new { |h, k| h[k] = [] }
    end

    def self.lex(match, &action)
      match = Regexp.new(Regexp.escape(match.to_s)) unless match.is_a?(Regexp)
      lexers[@current_scope] << [match, action]
    end

    DIRECTIVES = %w[if else elsif endif for endfor]

    scope :default do
      lex('@@') { :ATCHAR }
      lex('@') { push(:directive); next_token }

      # Swallow whitespace
      DIRECTIVES.each do |name|
        token = name.to_sym.upcase
        lex(/\n *@#{name}/) { push(:directive); token }
      end

      lex(/([^@]+)(?=\n\s*@)/) { :TEXT }
      lex(/[^@]+/) { :TEXT }
    end

    scope :directive do
      DIRECTIVES.each do |name|
        token = name.to_sym.upcase
        lex(name) { token }
      end

      lex('call') { push(:call); :CALL }
      lex(/\w+/) { :IDENT }
      lex('.') { :DOT }
      lex('(') { push(:idirective); :LPAREN }
      lex(/./m) { pop; less; next_token }
    end

    scope :idirective do
      lex(' in ') { :IN }
      lex(/\s+/) { next_token }
      lex(/\d+/) { :NUMBER }
      lex(/\w+/) { :IDENT }
      lex('.') { :DOT }
      lex('=') { :EQ }
      lex(')') { pop; pop; :RPAREN }
    end

    scope :call do
      lex('(') { :LPAREN }
      lex(',') { pop; push(:idirective); :COMMA }
      lex(')') { pop; pop; :RPAREN }
      lex(/[\w\.\/]+/) { :CNAME }
    end
  end
end

