# Creating/Testing puppet-st2 changes

One popular use case is using the workroom to test out additional features or bug-fixes for the StackStorm Puppet module. It is possible to test branch-level changes using workroom to ensure features are complete and bug-free.

## Steps:

0. Make changes to the `puppet-st2` module in a new feature branch, and push changes to GitHub.
1. Open up the `Puppetfile` at the root of the repository.
2. Locate the line labeled `mod 'stackstorm-st2'`
3. Change the line to download from upstream `git`:

```ruby
mod 'stackstorm-st2',
  :git => 'https://github.com/StackStorm/puppet-st2',
  :ref => '<name of feature branch>'
```

4. Run `update-system` with the environment `current_working_directory` to test chonges. (See below for commands)
5. Once tested, submit pull request.

## Updating System

There are several ways to run workroom, and as such you will need to know how to run `update-system` for your specific environment.

### Vagrant

```
vagrant rsync st2
vagrant provision st2
```

### BYOBox

```
ENV=current_working_directory update-system
```


