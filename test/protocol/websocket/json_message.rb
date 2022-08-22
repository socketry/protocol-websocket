require 'protocol/websocket/json_message'

describe Protocol::WebSocket::JSONMessage do
	let(:object) {{text: "Hello World", number: 42}}
	let(:message) {subject.generate(object)}
	
	it "can round-trip basic object" do
		expect(message.parse).to be == object
	end
end
