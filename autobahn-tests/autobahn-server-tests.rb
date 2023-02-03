#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021, by Aurora Nockert.
# Copyright, 2022-2023, by Samuel Williams.

require "fileutils"
require "json"

Kernel.system("pip install autobahntestsuite", exception: true)

falcon = Process.spawn("bundle exec #{__dir__}/autobahn-echo-server.ru", pgroup: true)
falcon_pg = Process.getpgid(falcon)

Kernel.system("wstest -m fuzzingclient", chdir: __dir__, exception: true)

Process.kill("KILL", -falcon_pg)

result = JSON.parse(File.read("/tmp/autobahn-server/index.json"))["protocol-websocket"]

FileUtils.rm_r("/tmp/autobahn-server/")

def failed_state(name)
	name != "OK" and name != "INFORMATIONAL"
end

failed = result.select do |_, outcome|
	failed_state(outcome["behavior"]) || failed_state(outcome["behaviorClose"])
end

puts "#{result.count - failed.count} / #{result.count} tests OK"

failed.each { |k, _| puts "#{k} failed" }

exit(1) if failed.count > 0
