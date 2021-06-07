#!/usr/bin/env ruby

require "fileutils"
require "json"

Kernel.system("pip install autobahntestsuite", exception: true)

falcon = Process.spawn("bundle exec #{__dir__}/autobahn-echo-server.ru", pgroup: true)
falcon_pg = Process.getpgid(falcon)

Kernel.system("wstest -m fuzzingclient", chdir: __dir__, exception: true)

Process.kill("KILL", -falcon_pg)

result = JSON.parse(File.read("/tmp/autobahn-server/index.json"))["protocol-websocket"]

FileUtils.rm_r("/tmp/autobahn-server/")

failed = result.select { |_, e| e["behavior"] != "OK" || e["behaviorClose"] != "OK" }

puts "#{result.count - failed.count} / #{result.count} tests OK"

failed.each { |k, _| puts "#{k} failed" }

exit(1) if failed.count > 0
