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
	
	gem "bake-test"
	gem "bake-test-external"
	
	# gem "async-websocket"
	gem "falcon"
end

gem "async-websocket", path: "../async-websocket"
