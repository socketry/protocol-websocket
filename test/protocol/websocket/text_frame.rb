# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require 'protocol/websocket/a_websocket_frame'
require 'protocol/websocket/text_frame'

describe Protocol::WebSocket::TextFrame do
	let(:frame) {subject.new}
	
	it "contains data" do
		expect(frame).to be(:data?)
	end
	
	it "isn't a control frame" do
		expect(frame).not.to be(:control?)
	end
	
	with "with mask" do
		let(:frame) {subject.new(mask: "abcd").pack("Hello World")}
		
		it_behaves_like Protocol::WebSocket::AWebSocketFrame
		
		it "encodes binary representation" do
			buffer = StringIO.new
			
			frame.write(buffer)
			
			expect(buffer.string).to be == "\x81\x8Babcd)\a\x0F\b\x0EB4\v\x13\x0E\a"
		end
	end
	
	with "without mask" do
		let(:frame) {subject.new.pack("Hello World")}
		
		it_behaves_like Protocol::WebSocket::AWebSocketFrame
		
		it "encodes binary representation" do
			buffer = StringIO.new
			
			frame.write(buffer)
			
			expect(buffer.string).to be == "\x81\vHello World"
		end
	end
end
