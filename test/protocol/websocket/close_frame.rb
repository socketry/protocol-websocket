# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/websocket/close_frame'

describe Protocol::WebSocket::CloseFrame do
	let(:frame) {subject.new}
	
	it "doesn't contain data" do
		expect(frame).not.to be(:data?)
	end
	
	it "is a control frame" do
		expect(frame).to be(:control?)
	end
	
	with '#pack' do
		it "can pack a close frame" do
			frame.pack(1000, "Hello World")
			
			expect(frame.payload).to be == "\x03\xE8Hello World".b
		end
	end
end
