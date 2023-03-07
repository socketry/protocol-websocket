# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2019, by Soumya.

require 'socket'
require 'protocol/websocket/connection'

describe Protocol::WebSocket::Connection do
	let(:sockets) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	
	let(:client) {Protocol::WebSocket::Framer.new(sockets.first)}
	let(:server) {Protocol::WebSocket::Framer.new(sockets.last)}
	
	let(:connection) {subject.new(server)}
	
	it "can manipulate open/closed state" do
		expect(connection).not.to be(:closed?)
		connection.close!
		expect(connection).to be(:closed?)
		connection.open!
		expect(connection).not.to be(:closed?)
	end
	
	it "doesn't generate mask by default" do
		expect(connection.mask).to be == nil
	end
	
	with "masked connection" do
		let(:connection) {subject.new(server, mask: true)}
		
		it "generates valid mask" do
			frame = connection.send_text("Hello World")
			expect(frame.mask).to be(:kind_of?, String)
			expect(frame.mask.bytesize).to be == 4
		end
	end
	
	with '#reserve!' do
		let(:bit) {Protocol::WebSocket::Frame::RSV1}
		
		it "can reserve a bit" do
			expect(connection.reserved & bit).not.to be(:zero?)
			connection.reserve!(bit)
			expect(connection.reserved & bit).to be(:zero?)
		end
		
		it "can't reserve the same bit twice" do
			connection.reserve!(bit)
			
			expect do
				connection.reserve!(bit)
			end.to raise_exception(ArgumentError, message: be =~ /Unable to use/)
		end
	end
	
	with "fragmented frames" do
		let(:text_frame) do
			Protocol::WebSocket::TextFrame.new(false).tap{|frame| frame.pack("Hello ")}
		end
		
		let(:binary_frame) do
			Protocol::WebSocket::BinaryFrame.new(false).tap{|frame| frame.pack "Hello World!"}
		end
		
		let(:ping_frame) do
			Protocol::WebSocket::PingFrame.new.tap{|frame| frame.pack("Yo")}
		end
		
		let(:continuation_frame) do
			Protocol::WebSocket::ContinuationFrame.new(true).tap{|frame| frame.pack("world!")}
		end
		
		it "can reconstruct fragmented message" do
			client.write_frame(text_frame)
			client.write_frame(ping_frame)
			client.write_frame(continuation_frame)
			
			message = connection.read
			expect(message).to be == "Hello world!"
			expect(message.encoding).to be == Encoding::UTF_8
			
			expect(client.read_frame).to be == ping_frame.reply
		end
		
		it "rejects text frames when expecting continuation" do
			client.write_frame(text_frame)
			client.write_frame(text_frame)
			
			expect do
				connection.read
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /expecting continuation/)
		end
		
		it "rejects text frames when expecting continuation" do
			client.write_frame(binary_frame)
			client.write_frame(binary_frame)
			
			expect do
				connection.read
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /expecting continuation/)
		end
		
		it "rejects continuation frames if they are not expected" do
			client.write_frame(continuation_frame)
			
			expect do
				connection.read
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /unexpected continuation/)
		end
	end
	
	with "#send_text" do
		it "can send and receive text frames" do
			connection.send_text("Hello World".encode(Encoding::UTF_8))
			
			expect(client.read_frame).to be(:kind_of?, Protocol::WebSocket::TextFrame)
		end
	end
	
	with "#send_binary" do
		it "can send and receive binary frames" do
			connection.send_binary("Hello World")
			
			expect(client.read_frame).to be(:kind_of?, Protocol::WebSocket::BinaryFrame)
		end
	end
	
	with '#read_frame' do
		it "rejects frames with reserved flags set" do
			frame = Protocol::WebSocket::TextFrame.new
			frame.pack "Hello World!"
			frame.flags = Protocol::WebSocket::Frame::RSV1
			
			client.write_frame(frame)
			
			expect do
				connection.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /reserved flags set/)
		end
		
		it "closes connection if general exception occurs during processing" do
			frame = Protocol::WebSocket::TextFrame.new
			frame.pack "Hello World!"
			
			client.write_frame(frame)
			
			mock(server) do |mock|
				mock.replace(:read_frame) do
					raise EOFError, "Fake error"
				end
			end
			
			expect do
				connection.read_frame
			end.to raise_exception(EOFError, message: be =~ /Fake error/)
			
			expect(connection).not.to be(:closed?)
			
			frame = client.read_frame
			expect(frame).to be_a(Protocol::WebSocket::CloseFrame)
		end
	end
	
	with '#receive_frame' do
		let(:frame) {Protocol::WebSocket::Frame.new}
		
		it "rejects unhandled frames" do
			expect do
				frame.apply(connection)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Unhandled frame/)
		end
	end
	
	with '#receive_close' do
		it "raises an exception when the close frame has an error code" do
			close_frame = Protocol::WebSocket::CloseFrame.new
			close_frame.pack(1001, "Fake error message")
			
			expect do
				close_frame.apply(connection)
			end.to raise_exception(Protocol::WebSocket::ClosedError, message: be =~ /Fake error message/)
			
			expect(connection).to be(:closed?)
		end
	end
	
	with '#send_ping' do
		it "can send a ping and receive a pong" do
			connection.send_ping
			frame = client.read_frame
			expect(frame).to be_a(Protocol::WebSocket::PingFrame)
			
			pong_frame = frame.reply(mask: connection.mask)
			client.write_frame(pong_frame)
			
			frame = connection.read_frame
			expect(frame).to be_a(Protocol::WebSocket::PongFrame)
		end
		
		it "can't send a ping in a closed state" do
			connection.close!
			
			expect do
				connection.send_ping
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Cannot send ping/)
		end
		
		it "can't receive a ping in a closed state" do
			ping_frame = Protocol::WebSocket::PingFrame.new
			
			connection.close!
			
			expect do
				connection.receive_ping(ping_frame)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Cannot receive ping/)
		end
	end
	
	with "different message lengths" do
		it "can handle a short message (<126)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 15)})
			end
			
			message = connection.read
			expect(message.size).to be == 15
			
			thread.join
		end

		it "can handle a medium message (<65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 60_000)})
			end
			
			message = connection.read
			expect(message.size).to be == 60_000
			
			thread.join
		end

		it "can handle large message (>65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 90_000)})
			end
			
			message = connection.read
			expect(message.size).to be == 90_000
			
			thread.join
		end
	end
	
	with "invalid unicode text message in 3 fragments" do
		let(:payload1) {"\xce\xba\xe1\xbd\xb9\xcf\x83\xce\xbc\xce\xb5".b}
		let(:payload2) {"\xf4\x90\x80\x80".b}
		let(:payload3) {"\x65\x64\x69\x74\x65\x64".b}
		
		it "fails with protocol error" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(false, payload1))
				client.write_frame(Protocol::WebSocket::ContinuationFrame.new(false, payload2))
				client.write_frame(Protocol::WebSocket::ContinuationFrame.new(true, payload3))
			end
			
			expect do
				connection.read
			end.to raise_exception(Protocol::WebSocket::ProtocolError)
			
			thread.join
		ensure
			client.close
			server.close
		end
	end
	
	with '#write' do
		it "can write strings (legacy text message)" do
			connection.write("Hello World!")
			
			frame = client.read_frame
			expect(frame.unpack).to be == "Hello World!"
		end
		
		it "can write binary strings (legacy binary message)" do
			connection.write("Hello World!".b)
			
			frame = client.read_frame
			expect(frame.unpack).to be == "Hello World!".b
		end
		
		it "can send text messages" do
			message = Protocol::WebSocket::TextMessage.new("Hello World!")
			connection.write(message)
			
			frame = client.read_frame
			expect(frame.unpack).to be == "Hello World!"
		end
	end
end
