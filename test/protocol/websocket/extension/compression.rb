# Copyright, 2022, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'server_context'

describe Protocol::WebSocket::Extension::Compression do
	include ServerContext
	
	with 'no extensions' do
		it "can send and receive a text message" do
			Async::WebSocket::Client.connect(endpoint, extensions: nil) do |client|
				expect(client.writer).not.to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).not.to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.write("Hello World")
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with 'default extensions' do
		it "can send and receive a text message using compression" do
			Async::WebSocket::Client.connect(endpoint) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.write("Hello World")
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with 'permessage-deflate; client_no_context_takeover; client_max_window_bits; server_no_context_takeover; server_max_window_bits=9' do
		let(:extensions) {::Protocol::WebSocket::Extensions::Client.new([
			[Protocol::WebSocket::Extension::Compression, {client_no_context_takeover: true, client_max_window_bits: true, server_no_context_takeover: true, server_max_window_bits: 9}]
		])}
		
		it "can send and receive a text message using compression" do
			Async::WebSocket::Client.connect(endpoint, extensions: extensions) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
								
				client.write("Hello World")
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		rescue => error
			Console.logger.info(self, error)
		end
	end
end
