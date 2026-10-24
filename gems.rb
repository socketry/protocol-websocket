# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2026, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

source "https://rubygems.org"

# Specify your gem's dependencies in protocol-websocket.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-gem-github", "~> 0.7.0"
	gem "bake-modernize", "~> 0.66"
	
	gem "agent-context"
	
	gem "decode"
	
	gem "utopia-project"
end

group :test do
	gem "sus"
	gem "covered"
	gem "falcon"
	gem "async-websocket"
	gem "async-http"
	
	gem "rubocop"
	gem "rubocop-md"
	gem "rubocop-socketry"
	
	gem "sus-fixtures-async"
	gem "sus-fixtures-async-http"
	
	gem "bake-test"
	gem "bake-test-external"
end
