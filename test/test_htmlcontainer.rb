require 'helper'
require 'mockle/htmlcontainer'

module Mockle
  class TestHTMLContainer < TestCase
    attr_reader :html
    
    def setup
      @html = HTMLContainer.new
    end

    def test_content
      html.parse("Hello")
      assert_equal "Hello", html.prefix
    end

    def test_first_script
      html.parse("Hello world\n<script src=mockle.js></script> ignore")
      assert_equal "Hello world\n", html.prefix
    end

    def test_textarea
      html.parse <<-EOF
<html>
<script src="mockle.js"></script>
<textarea layout="layout.html">
  Hello
</textarea>

<textarea id="partial">
  Partial
</textarea>
EOF
    
      assert_equal "<html>\n", html.prefix
      assert_equal [
        [{"layout" => "layout.html"}, "\n  Hello\n"],
        [{"id" => "partial"}, "\n  Partial\n"],
      ], html.sources
    end

    def test_supertextarea
      html.parse <<-EOF
<html>
<script src="mockle.js"></script>
<textarea>
  <supertextarea>Yay!</supertextarea>
  <supersupertextarea>Yay!</supersupertextarea>
</textarea>
EOF
      
      expected = %{
  <textarea>Yay!</textarea>
  <supertextarea>Yay!</supertextarea>
}
      assert_equal [[{}, expected]], html.sources
    end

    def test_missing_close
      html.parse <<-EOF
<html>
<script src="mockle.js"></script>
<textarea>
  Hello
EOF
      
      expected = %{
  Hello
}
      assert_equal [[{}, expected]], html.sources
    end
  end
end

