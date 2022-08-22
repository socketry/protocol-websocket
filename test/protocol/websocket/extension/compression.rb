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
	
	with 'permessage-deflate; true; 12; false; 9' do
		let(:extensions) {::Protocol::WebSocket::Extensions::Client.new([
			[Protocol::WebSocket::Extension::Compression, {
				# client.writer.context_takeover = false; server.reader.context_takeover = false;
				client_no_context_takeover: true,
				
				# client.writer.window_bits = 12; server.reader.window_bits = 12;
				client_max_window_bits: 12,
				
				# server.writer.context_takeover = true; client.reader.context_takeover = true;
				server_no_context_takeover: false,
				
				# server.writer.window_bits = 9; client.reader.window_bits = 9;
				server_max_window_bits: 9
			}]
		])}
		
		def websocket_server(request, server)
			expect(server.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
			expect(server.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
			
			expect(server.writer.window_bits).to be == 9
			expect(server.writer.context_takeover).to be == true
			
			expect(server.reader.window_bits).to be == 12
			expect(server.reader.context_takeover).to be == false
			
			super
		end
		
		it "can send and receive a text message using compression" do
			Async::WebSocket::Client.connect(endpoint, extensions: extensions) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				expect(client.writer.window_bits).to be == 12
				expect(client.writer.context_takeover).to be == false
				
				expect(client.reader.window_bits).to be == 9
				expect(client.reader.context_takeover).to be == true
				
				client.write("Hello World")
				client.flush
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with 'permessage-deflate; false; 8; true; 13' do
		let(:extensions) {::Protocol::WebSocket::Extensions::Client.new([
			[Protocol::WebSocket::Extension::Compression, {
				# Absence of this extension parameter in an extension negotiation
				# response indicates that the server can decompress messages built by
				# the client using context takeover.
				client_no_context_takeover: false,
				
				# By including this extension parameter in an extension negotiation
				# response, a server limits the LZ77 sliding window size that the
				# client uses to compress messages.  This reduces the amount of memory
				# for the decompression context that the server has to reserve for the
				# connection.
				client_max_window_bits: 8,
				
				# Absence of this extension parameter in an extension negotiation offer
				# indicates that the client can decompress a message that the server
				# built using context takeover.
				server_no_context_takeover: true,
				
				# Absence of this parameter in an extension negotiation offer indicates
				# that the client can receive messages compressed using an LZ77 sliding
				# window of up to 32,768 bytes.
				server_max_window_bits: 13
			}]
		])}
		
		def websocket_server(request, server)
			expect(server.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
			expect(server.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
			
			expect(server.writer.window_bits).to be == 13
			expect(server.writer.context_takeover).to be == false
			
			expect(server.reader.window_bits).to be == 9
			expect(server.reader.context_takeover).to be == true
			
			super
		end
		
		it "can send and receive a text message using compression" do
			Async::WebSocket::Client.connect(endpoint, extensions: extensions) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				expect(client.writer.window_bits).to be == 9
				expect(client.writer.context_takeover).to be == true
				
				expect(client.reader.window_bits).to be == 13
				expect(client.reader.context_takeover).to be == false
				
				client.write("Hello World")
				client.flush
				expect(client.read).to be == "Hello World"
			end
		end
	end
end
