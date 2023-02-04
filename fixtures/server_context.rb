# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require_relative 'reactor_context'

require 'protocol/http/middleware/builder'

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/io/shared_endpoint'
require 'async/websocket/adapters/http'
require 'async/websocket/client'

module ServerContext
	include ReactorContext
	
	def protocol
		Async::HTTP::Protocol::HTTP1
	end
	
	def endpoint
		Async::HTTP::Endpoint.parse('http://127.0.0.1:9294', timeout: 0.8, reuse_port: true, protocol: protocol)
	end
	
	def retries
		1
	end
	
	class WebSocketServer < ::Protocol::HTTP::Middleware
		def initialize(handler)
			@handler = handler
			super(nil)
		end
		
		def call(request)
			Async::WebSocket::Adapters::HTTP.open(request) do |connection|
				@handler.websocket_server(request, connection)
			end or super
		end
	end
	
	def websocket_server(request, connection)
		while message = connection.read
			message.send(connection)
		end
	end
	
	def app
		WebSocketServer.new(self)
	end
	
	def server
		Async::HTTP::Server.new(app, @bound_endpoint)
	end
	
	def client
		@client
	end
	
	def before
		@client = Async::HTTP::Client.new(endpoint, protocol: endpoint.protocol, retries: retries)
		
		# We bind the endpoint before running the server so that we know incoming connections will be accepted:
		@bound_endpoint = Async::IO::SharedEndpoint.bound(endpoint)
		
		# I feel a dedicated class might be better than this hack:
		mock(@bound_endpoint) do |mock|
			mock.replace(:protocol) {endpoint.protocol}
			mock.replace(:scheme) {endpoint.scheme}
		end
		
		@server_task = Async do
			server.run
		end
	end
	
	def after
		@client&.close
		@server_task&.stop
		@bound_endpoint&.close
	end
end
