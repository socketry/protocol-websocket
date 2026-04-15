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
	end
end
