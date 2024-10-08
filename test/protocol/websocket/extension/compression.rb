# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require "protocol/websocket/extension/compression"

require "async/websocket"
require "async/websocket/adapters/http"
require "sus/fixtures/async/reactor_context"
require "sus/fixtures/async/http/server_context"

describe Protocol::WebSocket::Extension::Compression do
	include Sus::Fixtures::Async::HTTP::ServerContext
	
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
	
	with "no extensions" do
		it "can send and receive a text message" do
			Async::WebSocket::Client.connect(client_endpoint, extensions: nil) do |client|
				expect(client.writer).not.to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).not.to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.send_text("Hello World")
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with "default extensions" do
		it "can send and receive a text message using compression" do
			Async::WebSocket::Client.connect(client_endpoint) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				expect(client.reader).to have_attributes(
					to_s: be =~ /window_bits=15 context_takeover=true/
				)
				
				expect(client.writer).to have_attributes(
					to_s: be =~ /window_bits=15 context_takeover=true/
				)
				
				client.send_text("Hello World")
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
		
		it "can send and receive a text message without compression" do
			Async::WebSocket::Client.connect(client_endpoint) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.send_text("Hello World", compress: false)
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
		
		it "can send and receive a binary message using compression" do
			Async::WebSocket::Client.connect(client_endpoint) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.send_binary("Hello World", compress: true)
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
		
		it "can send and receive a binary message without compression" do
			Async::WebSocket::Client.connect(client_endpoint) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				client.send_binary("Hello World", compress: false)
				client.flush
				
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with "permessage-deflate; true; 12; false; 9" do
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
			Async::WebSocket::Client.connect(client_endpoint, extensions: extensions) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				expect(client.writer.window_bits).to be == 12
				expect(client.writer.context_takeover).to be == false
				
				expect(client.reader.window_bits).to be == 9
				expect(client.reader.context_takeover).to be == true
				
				client.send_text("Hello World")
				client.flush
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with "permessage-deflate; false; 8; true; 13" do
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
			Async::WebSocket::Client.connect(client_endpoint, extensions: extensions) do |client|
				expect(client.writer).to be_a(Protocol::WebSocket::Extension::Compression::Deflate)
				expect(client.reader).to be_a(Protocol::WebSocket::Extension::Compression::Inflate)
				
				expect(client.writer.window_bits).to be == 9
				expect(client.writer.context_takeover).to be == true
				
				expect(client.reader.window_bits).to be == 13
				expect(client.reader.context_takeover).to be == false
				
				client.send_text("Hello World")
				client.flush
				expect(client.read).to be == "Hello World"
			end
		end
	end
	
	with "#offer" do
		it "fails if local maximum window bits is out of bounds" do
			expect do
				subject.offer(client_max_window_bits: 20)
			end.to raise_exception(ArgumentError, message: be =~ /Invalid local maximum window bits/)
		end
		
		it "fails if remote maximum window bits is out of bounds" do
			expect do
				subject.offer(server_max_window_bits: 20)
			end.to raise_exception(ArgumentError, message: be =~ /Invalid remote maximum window bits/)
		end
	end
	
	with "#negotiate" do
		it "fails if invalid option is given" do
			expect do
				subject.negotiate(["foo", "bar"])
			end.to raise_exception(ArgumentError, message: be =~ /Unknown option: foo/)
		end
	end
	
	with "#accept" do
		it "fails if invalid option is given" do
			expect do
				subject.accept(["foo", "bar"])
			end.to raise_exception(ArgumentError, message: be =~ /Unknown option: foo/)
		end
	end
end
