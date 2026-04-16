# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require "protocol/websocket/framer"

describe Protocol::WebSocket::Framer do
	let(:stream) {StringIO.new}
	let(:framer) {subject.new(stream)}
	
	with "#write_frame" do
		it "fails with invalid mask size" do
			frame = Protocol::WebSocket::Frame.new(true, "12345")
			frame.mask = "bad"
			
			expect do
				framer.write_frame(frame)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid mask length/)
		end
		
		it "writes a text frame and reads it back" do
			output = StringIO.new
			writer = Protocol::WebSocket::Framer.new(output)
			
			frame = Protocol::WebSocket::TextFrame.new(true, "Hello")
			writer.write_frame(frame)
			
			reader = Protocol::WebSocket::Framer.new(StringIO.new(output.string))
			received = reader.read_frame
			expect(received).to be_a(Protocol::WebSocket::TextFrame)
			expect(received.payload).to be == "Hello"
		end
	end
	
	with "#read_frame" do
		it "fails if it can't read the frame header" do
			expect do
				framer.read_frame
			end.to raise_exception(EOFError, message: be =~ /Could not read frame header/)
		end
		
		it "rejects reserved non-control opcodes" do
			stream.string = "\x83\x00"
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Non-control opcode.*reserved/)
		end
		
		it "rejects reserved control opcodes" do
			stream.string = "\x8B\x00"
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Control opcode.*reserved/)
		end
		
		it "rejects invalid control frame payload length" do
			# FIN=1, opcode=0x8 (close), MASK=1, length=127 → violates max 125 for control frames
			stream.string = "\x88\xFF"
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid control frame payload length/)
		end
		
		it "rejects fragmented control frames" do
			# FIN=0, opcode=0x8 (close), MASK=0, length=15
			stream.string = "\x08\x0F"
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Fragmented control frame/)
		end
		
		it "rejects frames bigger than the maximum frame size" do
			# FIN=1, opcode=0x2 (binary), MASK=0, length=125
			stream.string = "\x82\x7D"
			stream.rewind
			
			expect do
				framer.read_frame(124)
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid payload length: \d+ > \d+!/)
		end
		
		it "rejects frames with truncated payload" do
			# FIN=1, opcode=0x2 (binary), MASK=0, length=5, only 4 bytes of payload
			stream.string = "\x82\x051234"
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(EOFError, message: be =~ /Incorrect payload length: \d+ != \d+!/)
		end
		
		it "reads a text frame" do
			# FIN=1, opcode=0x1 (text), MASK=0, length=5, payload="Hello"
			stream.string = "\x81\x05Hello"
			stream.rewind
			
			frame = framer.read_frame
			expect(frame).to be_a(Protocol::WebSocket::TextFrame)
			expect(frame.payload).to be == "Hello"
			expect(frame.mask).to be == false
		end
	end
end
