require 'protocol/websocket/extensions'

describe Protocol::WebSocket::Extensions do
	it "can parse headers" do
		extensions = subject.parse([
			"permessage-deflate; client_max_window_bits=10",
		]).to_a
		
		expect(extensions).to be == [
			["permessage-deflate", [["client_max_window_bits", "10"]]]
		]
	end
end
