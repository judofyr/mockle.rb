require 'helper'
require 'mockle/engine'

module Mockle
  class TestEngine < TestCase
    def execute(str, ctx = {})
      engine = Engine.new
      code = engine.call(str)
      eval(code)
    end

    def test_static
      assert_equal "Hello", execute("Hello")
    end

    def test_get
      assert_equal "Magnus", execute("@name", :name => "Magnus")
      assert_equal "Magnus", execute("@(name)", :name => "Magnus")
    end

    def test_get_hash
      assert_equal "Magnus", execute("@person.name", :person => { :name => "Magnus" })
      assert_equal "Magnus", execute("@person.name", :person => { "name" => "Magnus" })
    end

    class Person
      attr_accessor :name

      def initialize(name)
        @name = name
      end
    end

    def test_get_method
      me = Person.new("Magnus")
      assert_equal "Magnus", execute("@person.name", :person => me)
    end

    def test_indirect
      me = Person.new("Magnus")
      assert_equal "Magnus", execute("@person.(type)", :person => me, :type => :name)
    end

    def test_array
      people = [Person.new("Magnus"), Person.new("Rob")]
      assert_equal "Magnus & Rob", execute("@people.0.name & @people.1.name", :people => people)
    end

    def test_if
      assert_equal "a", execute("@if(a)a@else()b@end", :a => true)
      assert_equal "b", execute("@if(a)a@else()b@end", :a => false)
    end

    def test_tricky_lvars
      res = execute "@(a = 1)@a@for(a in b)@a@end@a", :b => [0, 1, 2, 3]
      assert_equal "101233", res

      res = execute "@for(a in b)@a@end@a", :b => [0, 1, 2, 3]
      assert_equal "01233", res
    end

    def test_global
      res = execute("@($a=1)@a@(a=2)@a@$a")
      assert_equal "121", res

      me = Person.new('Magnus')
      ha = { :name => 'Rob' }

      res = execute("@a.name@($a=b)@a.name", :a => me, :b => ha)
      assert_equal "MagnusRob", res
    end

    def test_whitespace
      people = [Person.new('Magnus'), Person.new('Rob')]
      res = execute <<-EOF, :people => people
<ul>
@for(person in people)
  @if(person.name)
    <li>@person.name
  @end
@end
</ul>
EOF
      
      assert_equal <<-EOF, res
<ul>
    <li>Magnus
    <li>Rob
</ul>
EOF
    end

    def test_math
      assert_equal "7", execute("@(1+2*3-4/5%6)")
    end
  end
end

