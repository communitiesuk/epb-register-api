
task :time_rake do
  pp "______________"
  pp Time.now
  pp "______________"
  pp Time.now.zone
  pp "______________"
  pp Time.now.utc
  pp "______________"
end
