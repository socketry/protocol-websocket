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
