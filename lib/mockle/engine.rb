require 'temple'
require 'mockle/parser'
require 'mockle/compiler'

module Mockle
  class Engine < Temple::Engine
    use Parser
    use Compiler
    filter :ControlFlow
    filter :MultiFlattener
    filter :StaticMerger
    filter :DynamicInliner
    generator :ArrayBuffer
  end
end

