# frozen_string_literal: true

require_relative "lib/protocol/websocket/version"

Gem::Specification.new do |spec|
	spec.name = "protocol-websocket"
	spec.version = Protocol::WebSocket::VERSION
	
	spec.summary = "A low level implementation of the WebSocket protocol."
	spec.authors = ["Samuel Williams", "Aurora Nockert", "Soumya", "Olle Jonsson", "William T. Nelson"]
	spec.license = "MIT"
	
	spec.cert_chain  = ['release.cert']
	spec.signing_key = File.expand_path('~/.gem/release.pem')
	
	spec.homepage = "https://github.com/socketry/protocol-websocket"
	
	spec.files = Dir.glob(['{lib}/**/*', '*.md'], File::FNM_DOTMATCH, base: __dir__)
	
	spec.required_ruby_version = ">= 2.5.0"
	
	spec.add_dependency "protocol-http", "~> 0.2"
	spec.add_dependency "protocol-http1", "~> 0.2"
	
	spec.add_development_dependency "bundler"
	spec.add_development_dependency "covered"
	spec.add_development_dependency "sus", "~> 0.16"
end
