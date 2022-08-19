source "https://rubygems.org"

# Specify your gem's dependencies in protocol-websocket.gemspec
gemspec

group :maintenance, optional: true do
	gem "bake-gem"
	gem "bake-modernize"
	
	gem "utopia-project"
end

group :autobahn_tests, optional: true do
	gem "async-websocket", github: "socketry/async-websocket"
	gem "falcon"
end

group :test do
	gem "bake-test"
	gem "bake-test-external"
end
