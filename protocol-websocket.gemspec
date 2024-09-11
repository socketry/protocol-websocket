# frozen_string_literal: true

require_relative "lib/protocol/websocket/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-websocket"
	spec.version = Protocol::WebSocket::VERSION
	
	spec.summary = "A low level implementation of the WebSocket protocol."
	spec.authors = ["Samuel Williams", "Aurora Nockert", "Soumya", "Olle Jonsson", "William T. Nelson"]
	spec.license = "MIT"
	
	spec.cert_chain  = ["release.cert"]
	spec.signing_key = File.expand_path("~/.gem/release.pem")
	
	spec.homepage = "https://github.com/socketry/protocol-websocket"
	
	spec.metadata = {
		"documentation_uri" => "https://socketry.github.io/protocol-websocket/",
		"source_code_uri" => "https://github.com/socketry/protocol-websocket.git",
	}
	
	spec.files = Dir.glob(["{lib}/**/*", "*.md"], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 3.1"
	
	spec.add_dependency "protocol-http", "~> 0.2"
end
