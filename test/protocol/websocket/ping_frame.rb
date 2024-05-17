# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/websocket/ping_frame'

describe Protocol::WebSocket::PingFrame do
	let(:frame) {subject.new}
	
	it "doesn't contain data" do
		expect(frame).not.to be(:data?)
	end
	
	it "is a control frame" do
		expect(frame).to be(:control?)
	end
end
