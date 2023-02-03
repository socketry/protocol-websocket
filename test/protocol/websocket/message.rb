require 'protocol/websocket/message'

describe Protocol::WebSocket::Message do
	let(:buffer) {"Hello World!"}
	let(:message) {subject.new(buffer)}
	
	it "can round-trip basic object" do
		expect(message.to_str).to be == buffer
	end
end
