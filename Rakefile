require 'rubygems'
require 'bundler/setup'

ROOT_DIR = File.expand_path('.')
Dir.glob('script/tasks/*.rake').each { |r| load r }

desc "Run all RSpec code examples"
RSpec::Core::RakeTask.new(:rspec) do |t|
  File.exist?('spec/spec.opts') ? opts = File.read("spec/spec.opts").chomp : opts = ""
  t.rspec_opts = opts
end

SPEC_SUITES = (Dir.entries('spec') - ['.', '..','fixtures']).select {|e| File.directory? "spec/#{e}" }
namespace :rspec do
  SPEC_SUITES.each do |suite|
    desc "Run #{suite} RSpec code examples"
    RSpec::Core::RakeTask.new(suite) do |t|
      t.pattern = "spec/#{suite}/**/*_spec.rb"
      File.exist?('spec/spec.opts') ? opts = File.read("spec/spec.opts").chomp : opts = ""
      t.rspec_opts = opts
    end
  end
end
task :default => :rspec

begin
  if Gem::Specification::find_by_name('puppet-lint')
    require 'puppet-lint/tasks/puppet-lint'
    PuppetLint.configuration.ignore_paths = ["spec/**/*.pp", "vendor/**/*.pp"]
    task :default => [:rspec, :lint]
  end
rescue Gem::LoadError
end

