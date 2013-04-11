require 'rake/testtask'

task :default => :test

Rake::TestTask.new do |t|
  t.libs << 'test'
end

task :generate => 'lib/mockle/parser.rb'

rule '.rb' => '.y' do |t|
  sh "racc", t.source, "-o", t.name
end

