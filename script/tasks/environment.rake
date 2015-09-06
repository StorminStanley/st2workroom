$stdout.sync = true

namespace :environments do
  desc "Update one or more branches "
  task :update, :branch do |_, args|
    branch = args[:branch] || 'all'

    log "Pruning origin"
    git(:remote, :prune, :origin)

    repo_dir  = ENV['ROOT_DIR'] || '/opt/puppet'
    envs_dir  = ENV['PUPPET_ENV_DIR'] || "#{ROOT_DIR}/environments"

    log "Loading list of branches"

    all_branches  = git(:branch, '-a').split(/\W*\n\W*/)
    branches      = all_branches.map {|r| remote_branch_name(r) }.compact

    # Unless specified, only deploy the requested branch
    branch.eql?('all') ? deploy = branches : deploy = branch

    Rake::Task['environments:cleanup'].invoke(envs_dir, branches)
    Rake::Task['environments:setup'].invoke(envs_dir, repo_dir, deploy)
    Rake::Task['environments:symlink'].invoke(envs_dir)
  end

  desc "Clean up old branches from upstream"
  task :cleanup, :dir, :branches do |_, args|
    dir, branches = args[:dir], args[:branches]

    log "Cleaning up deleted branches from #{Dir.pwd}"

    Dir.chdir(dir) do
      current_envs = Dir['*']

      current_envs.each do |env|
        next if env == 'current_working_directory'
        next if branches.include? env
        next if branches.any?{ |branch| branch.gsub(/\W/,'_') == env }
        puts "Removing environment #{env}"
        FileUtils.rm_rf env
      end
    end
  end

  desc "Deploy a branch"
  task :setup, :env_dir, :repo_dir, :branches do |_, args|
    environments_dir, repo_dir, branches = args[:env_dir], args[:repo_dir], args[:branches]

    Array(branches).each do |branch|
      log "Setting up branch #{branch} from #{Dir.pwd}"

      env_checkout = "#{environments_dir}/#{branch.gsub(/\W/,'_')}"

      Dir.chdir(repo_dir) do
        log "Updating git root from #{Dir.pwd}"
        git(:fetch, '--all')

        log "Running gc on git root."
        git(:gc, '--auto')
      end

      log "Cloning initial branch environment #{branch}"
      git(:clone, '--mirror', repo_dir, "#{env_checkout}.tmp/.git")

      Dir.chdir("#{env_checkout}.tmp") do
        log "Turning bare mirror into regular repository"
        git(:config, '--bool', 'core.bare', 'false')
        log "Resetting branch environment to origin/#{branch}"
        git(:reset, '--hard', "origin/#{branch}")

        local_branch_sha = git('show', '-s', '--pretty=format:%H', 'HEAD').strip
        log "Environment #{branch} is currently on #{local_branch_sha}"
      end

      log "Deploying new branch environment #{branch}"
      FileUtils.mv env_checkout, "#{env_checkout}.old" if File.directory? env_checkout
      FileUtils.mv "#{env_checkout}.tmp", env_checkout
      FileUtils.rm_rf "#{env_checkout}.old" if File.directory? "#{env_checkout}.old"
    end
  end

  task :symlink, :environments_dir do |_, args|
    environments_dir = args[:environments_dir]

    unless Dir.exists?("#{environments_dir}/production") do
      log "Creating production symlinks"
      Dir.chdir(environments_dir) do
        ln_nfs 'master', 'production'
      end
    end
    end
    end
end
