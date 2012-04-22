require 'strscan'

module Mockle
  class HTMLContainer
    attr_accessor :prefix, :sources

    def parse(input)
      @sources = []

      if input =~ /<script/
        @prefix = $`
        parse_textarea($')
      else
        @prefix = input
      end
    end

    def push_static(res, str)
      res << [:static, str]
    end

    def parse_textarea(input)
      while input =~ /<textarea\b([^>]*)>/
        stop = $'.index('</textarea>') || $'.size
        content = expand_supertextarea($'[0, stop])
        @sources << [parse_attributes($1), content]
        input = $'[stop..-1]
      end
    end

    def parse_attributes(input)
      Hash[input.scan(/([^= ]+)=["']([^"']*)["']/)]
    end

    def expand_supertextarea(str)
      str.gsub(%r|(</?)super(super)*textarea\b|, '\1\2textarea')
    end
  end
end

