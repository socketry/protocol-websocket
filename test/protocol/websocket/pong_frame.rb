# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require "protocol/websocket/pong_frame"

describe Protocol::WebSocket::PongFrame do
	let(:frame) {subject.new}
	
	it "doesn't contain data" do
		expect(frame).not.to be(:data?)
	end
	
	it "is a control frame" do
		expect(frame).to be(:control?)
	end
	
	with "#apply" do
		let(:connection) {Protocol::WebSocket::Connection.new(nil)}
		
		it "can apply itself to a connection" do
			expect(connection).to receive(:receive_pong).with(frame).and_return(nil)
			frame.apply(connection)
		end
	end
end
