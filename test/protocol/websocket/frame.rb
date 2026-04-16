# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2025, by Samuel Williams.
# Copyright, 2025, by Taleh Zaliyev.

require "protocol/websocket/frame"

describe Protocol::WebSocket::Frame do
	let(:frame) {subject.new}
	
	with "#pack" do
		it "rejects excessively large frames" do
			data = String.new
			expect(data).to receive(:bytesize).and_return(2**64)
			
			expect do
				frame.pack(data)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /bigger than allowed/)
		end
	end
	
	with "#apply" do
		let(:connection) {Protocol::WebSocket::Connection.new(nil)}
		
		it "can apply itself to a connection" do
			expect(connection).to receive(:receive_frame).with(frame).and_return(nil)
			frame.apply(connection)
		end
	end
	
	with ".read" do
		it "rejects invalid control frame payload length" do
			stream = StringIO.new("\xFF")
			
			expect do
				subject.read(true, 0, 0x8, stream, 128)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid control frame payload length/)
		end
		
		it "rejects fragmented control frames" do
			stream = StringIO.new("\x0F")
			
			expect do
				subject.read(false, 0, 0x8, stream, 128)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Fragmented control frame/)
		end
		
		it "rejects frames bigger than the maximum frame size" do
			stream = StringIO.new("\x7D")
			
			expect do
				subject.read(false, 0, 0, stream, 124)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid payload length: \d+ > \d*!/)
		end
		
		it "rejects frames with truncated payload" do
			stream = StringIO.new("\x051234")
			
			expect do
				subject.read(false, 0, 0, stream, 128)
			end.to raise_exception(EOFError, message: be =~ /Incorrect payload length: \d+ != \d+!/)
		end
		
		it "accepts a pre-read second byte" do
			stream = StringIO.new("Hello")
			second_byte = 0x05
			
			frame = subject.read(true, 0, 0x1, stream, 128, second_byte)
			expect(frame.payload).to be == "Hello"
			expect(frame.mask).to be == false
		end
	end
	
	with ".write" do
		let(:stream) {StringIO.new}
		
		it "fails with invalid payload length" do
			frame.length = 5
			frame.payload = "1234"
			
			expect do
				frame.write(stream)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid payload length/)
		end
		
		it "fails with invalid mask size" do
			frame.length = 5
			frame.payload = "12345"
			frame.mask = "bad"
			
			expect do
				frame.write(stream)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid mask length/)
		end
	end
end
