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
		it "can pack a close frame with no error and a message" do
			frame.pack(1000, "Hello World")
			
			expect(frame.payload).to be == "\x03\xE8Hello World".b
		end
		
		it "forces UTF-8 encoding" do
			message = "Hello World".b
			
			frame.pack(1000, message)
			
			expect(frame.payload).to be == "\x03\xE8Hello World".b
		end
	end
	
	with '#unpack' do
		it "can unpack a close frame with a missing error and message" do
			frame.pack
			
			code, reason = frame.unpack
			expect(code).to be_nil
			expect(reason).to be_nil
		end
		
		it "rejects a close frame with an invalid format" do
			frame.payload = "1"
			frame.length = 1
			
			expect do
				frame.unpack
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid close frame length/)
		end
		
		it "rejects invalid close codes" do
			frame.pack(1)
			
			expect do
				frame.unpack
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid close code/)
		end
		
		it "rejects reserved close codes" do
			frame.pack(2000)
			
			expect do
				frame.unpack
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Reserved close code/)
		end
		
		it "rejects invalid UTF-8 encoded message" do
			frame.pack(1000, "Hello World!")
			frame.payload[2] = "\xFF".b
			
			expect do
				frame.unpack
			end.to raise_exception(Protocol::WebSocket::ProtocolError, message: be =~ /Invalid UTF-8 in close reason/)
		end
	end
end
