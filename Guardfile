#!/usr/bin/env ruby

# Start with the -w /opt/stackstorm/packs option.
guard :shell do
  watch /sensors/ do |file|
    puts "Reloading StackStorm Sensors..."
    `st2ctl reload --register-sensors`
    `st2ctl restart-component sensor_container`
  end

  watch /rules/ do |file|
    puts "Reloading StackStorm Rules..."
    `st2ctl reload --register-rules`
  end

  watch /actions/ do |file|
    puts "Reloading StackStorm Actions..."
   `st2ctl reload --register-actions`
  end
end


