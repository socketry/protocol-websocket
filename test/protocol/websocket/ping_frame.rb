require 'a_websocket_frame'
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
