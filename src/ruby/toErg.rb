#!/usr/bin/env ruby

require './tomrc.rb'
load ARGV[0]

print Workout.instance.toString()
