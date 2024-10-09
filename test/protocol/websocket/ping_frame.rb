# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023-2024, by Samuel Williams.

require "protocol/websocket/ping_frame"

describe Protocol::WebSocket::PingFrame do
	let(:frame) {subject.new}
	
	it "doesn't contain data" do
		expect(frame).not.to be(:data?)
	end
	
	it "is a control frame" do
		expect(frame).to be(:control?)
	end
	
	with "#reply" do
		it "can generate an appropriately masked reply" do
			frame.pack("Hello, World!")
			
			reply = frame.reply(mask: "mask")
			
			expect(reply.mask).to be == "mask"
			expect(reply.payload).not.to be == "Hello, World!"
			expect(reply.unpack).to be == "Hello, World!"
		end
	end
end
