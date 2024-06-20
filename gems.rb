# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

source "https://rubygems.org"

# Specify your gem's dependencies in protocol-websocket.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	
	gem "sus-fixtures-async"
	gem "sus-fixtures-async-http"
	
	gem "bake-test"
	gem "bake-test-external"
	
	# Used for autobahn tests.
	gem "falcon"
	gem "async-websocket"
	gem "async-http"
end
