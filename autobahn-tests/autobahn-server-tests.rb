#!/usr/bin/env ruby
# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2021, by Aurora Nockert.
# Copyright, 2022-2023, by Samuel Williams.

require "json"

config_root = File.expand_path("config", __dir__)
report_root = File.expand_path("report", __dir__)

falcon = Process.spawn("bundle", "exec", "./autobahn-echo-server.ru", chdir: __dir__, pgroup: true)
falcon_pg = Process.getpgid(falcon)

begin
	system("docker", "run", "--rm", "-v", "#{config_root}:/config", "-v", "#{report_root}:/reports", "--net=host", "--name", "wstest", "crossbario/autobahn-testsuite", "wstest", "-m", "fuzzingclient", "-s", "/config/fuzzingclient.json", chdir: __dir__, exception: true)
ensure
	Process.kill("KILL", -falcon_pg)
end

results_path = File.expand_path("index.json", report_root)
result = JSON.parse(File.read(results_path))["protocol-websocket"]

def failed_state(name)
	name != "OK" and name != "INFORMATIONAL"
end

failed = result.select do |_, outcome|
	failed_state(outcome["behavior"]) || failed_state(outcome["behaviorClose"])
end

puts "#{result.count - failed.count} / #{result.count} tests OK"

failed.each { |k, _| puts "#{k} failed" }

exit(1) if failed.count > 0
