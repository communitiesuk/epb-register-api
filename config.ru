require File.expand_path('lib/api', File.dirname(__FILE__))

log = File.new('sinatra.log', 'w')
$stdout.reopen(log)
$stderr.reopen(log)
$stderr.sync = true
$stdout.sync = true

run AssessorService