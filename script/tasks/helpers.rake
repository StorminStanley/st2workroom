def git(command, *args)
  arguments = args.map {|a| a.to_s }.join(' ')
  output = `git #{command} #{arguments} 2>&1`
  log output
  output
end

def remote_branch_name(full_branch_name)
  full_branch_name[%r{remotes/origin/([\w\-\/]*)$}, 1]
end


def librarian(dir)
  Dir.chdir(dir)
  puts `bundle exec librarian-puppet install`
end

def ln_nfs(source, dest)
  if File.exists?(dest) ||
    (File.symlink?(dest) && File.readlink(dest) != source)
    File.unlink dest
  end
  File.symlink source, dest
end

def log(message)
  timestr = Time.now.strftime("%H:%M:%S")
  puts "[#{timestr}] #{message}"
end
