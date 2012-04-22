require 'helper'
require 'mockle/parser'

module Mockle
  class TestParser < TestCase
    attr_reader :parser

    def setup
      @parser = Parser.new
    end

    def parse(str)
      res = Parser.new.parse(str)
      assert_equal :mockle, res[0]
      assert_equal :block, res[1]
      res[2]
    end

    def test_static
      assert_equal [:static, "Hello world!"], parse("Hello world!")
    end

    def test_double_at
      assert_equal [:multi,
        [:static, "judofyr"],
        [:static, "@"],
        [:static, "gmail.com"]
      ],
      parse("judofyr@@gmail.com")
    end

    def test_var
      assert_equal [:multi,
        [:static, "Welcome "],
        [:mockle, :output, [:mockle, :ctx, "name"]],
        [:static, "!"]
      ],
      parse("Welcome @name!")
    end

    def test_var_child
      assert_equal [:multi,
        [:static, "Welcome "],
        [:mockle, :output, [:mockle, :dot, [:mockle, :ctx, "user"], "name"]],
        [:static, "!"]
      ],
      parse("Welcome @user.name!")
    end

    def test_var_child_expr
      assert_equal [:multi,
        [:static, "Welcome "],
        [:mockle, :output,
          [:mockle, :dot, [:mockle, :ctx, "user"], [:mockle, :ctx, "name"]]],
        [:static, "!"]
      ],
      parse("Welcome @user.(name)!")
    end

    def test_concat
      assert_equal [:multi,
        [:static, "Welcome "],
        [:mockle, :output,
          [:mockle, :concat,
            [:mockle, :ctx, "name"],
            [:mockle, :ctx, "age"]]],
        [:static, "!"]
      ],
      parse("Welcome @(name age)!")
    end

    def test_arith
      assert_equal [:multi,
        [:mockle, :output,
          [:mockle, :op, " - ",
            [:mockle, :op, " + ",
              [:mockle, :num, "2"],
              [:mockle, :op, " * ",
                [:mockle, :num, "2"],
                [:mockle, :num, "5"]
              ]
            ],
            [:mockle, :num, "1"]
          ]
        ],
        [:static, "!"]
      ],
      parse("@(2 + 2 * 5 - 1)!")
    end

    def test_assignment
      assert_equal [:mockle, :assign,
        [:mockle, :var, "content"],
        [:mockle, :op, "*",
          [:mockle, :num, "2"],
          [:mockle, :ctx, "a"]
        ]
      ],
      parse("@(content=2*a)")

      assert_equal [:mockle, :assign,
        [:mockle, :lctx, "content"],
        [:mockle, :op, "*",
          [:mockle, :num, "2"],
          [:mockle, :ctx, "a"]
        ]
      ],
      parse("@($content=2*a)")
    end

    def test_locals
      lvar = [:mockle, :var, "content"]
      assert_equal [:multi,
        [:mockle, :assign, lvar,
          [:mockle, :num, "2"]],
        [:mockle, :output, lvar]
      ],
      parse("@(content=2)@content")
    end

    def test_if
      assert_equal [:mockle, :if,
        [:mockle, :op, " == ",
          [:mockle, :ctx, "a"],
          [:mockle, :ctx, "b"]],
        [:static, "hello"],
        nil
      ],
      parse("@if(a == b)hello@end")
    end

    def test_ifelse
      assert_equal [:mockle, :if,
        [:mockle, :ctx, "a"],
        [:static, "a"],
        [:mockle, :if,
          [:mockle, :ctx, "b"],
          [:static, "b"],
          [:static, "else"]]
      ],
      parse("@if(a)a@elseif(b)b@else()else@end")
    end

    def test_for
      assert_equal [:mockle, :for,
        [:mockle, :var, "a"],
        [:mockle, :ctx, "n"],
        [:multi,
          [:static, " hello "],
          [:mockle, :output, [:mockle, :var, "a"]],
          [:static, " "]
        ]
      ],
      parse("@for(a in n) hello @a @end")
    end

    def test_not
      assert_equal [:mockle, :if,
        [:mockle, :not,
          [:mockle, :ctx, "a"]],
        [:static, "hello"],
        nil
      ],
      parse("@if(!a)hello@end")
    end
  end
end

