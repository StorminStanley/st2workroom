$stdout.sync = true

namespace :bats do
  desc "Run the bats test suite"
  task :spec do
    sh('bats', 'spec/bats')
  end
end
