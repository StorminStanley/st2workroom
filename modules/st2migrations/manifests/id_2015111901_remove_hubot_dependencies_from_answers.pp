# Migration: Remove Hubot Dependencies from Answers
#
# The current mechanism to manage hubot dependencies via package.json
# is proving to be non-ideal. This migration accompanies changes in
# ::profile::hubot that instead moves responsibility of managing NPM
# from the hubot repo to Puppet
#
# To make this change, any users that have an answers file generated
# by st2installer before this date and the change made in
# https://github.com/StackStorm/st2installer/pull/82, this migration
# will take care of cleanup for them.
#
class st2migrations::id_2015111901_remove_hubot_dependencies_from_answers {
  $_shell_script = @("EOT"/)
  FILE=${::settings::confdir}/hieradata/answers.json

  if [ -f \$FILE ]; then
    cat \$FILE | python -c '
      import json,sys;
      obj = json.load(sys.stdin);
      obj.pop("hubot::dependencies", None);
      print json.dumps(obj);' > \$FILE.new

    mv \$FILE.new \$FILE
  fi
  | EOT

  ::st2migrations::definition { 'remove_hubot_dependencies_from_answers':
    id      => '2015111901',
    version => '1',
    script  => $_shell_script,
  }
}
