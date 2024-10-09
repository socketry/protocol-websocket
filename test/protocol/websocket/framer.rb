# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require "protocol/websocket/framer"

describe Protocol::WebSocket::Framer do
	let(:stream) {StringIO.new}
	let(:framer) {subject.new(stream)}
	
	with "#read_frame" do
		it "fails if it can't read the frame header" do
			expect do
				framer.read_frame
			end.to raise_exception(EOFError, message: be =~ /Could not read frame header/)
		end
	end
	
	with "requires_masking: true" do
		let(:framer) {subject.new(stream, requires_masking: true)}
		
		it "fails if it receives an unmasked frame" do
			frame = Protocol::WebSocket::BinaryFrame.new(true).pack("Hello, World!")
			frame.write(stream)
			
			stream.rewind
			
			expect do
				framer.read_frame
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Received unmasked frame but requires masking!/)
		end
	end
end
