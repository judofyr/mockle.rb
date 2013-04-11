$LOAD_PATH << File.expand_path('../../lib', __FILE__)
require 'minitest/autorun'

require 'simplecov'
SimpleCov.start do
  add_filter "/test/"
end

