# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

require_relative 'reactor_context'

require 'async/http/server'
require 'async/http/client'
require 'async/http/endpoint'
require 'async/io/shared_endpoint'

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
	
	def app
		->(env){[200, {}, ['Hello World!']]}
	end
	
	def middleware
		Protocol::Rack::Adapter.new(app)
	end
	
	def server
		Async::HTTP::Server.new(middleware, @bound_endpoint)
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
