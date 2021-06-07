source "https://rubygems.org"

# Specify your gem's dependencies in protocol-websocket.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-bundler"
	gem "bake-modernize"
end

group :autobahn_tests, optional: true do
	gem "async-websocket", github: "socketry/async-websocket"
	gem "falcon"
end