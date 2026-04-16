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
	
end
