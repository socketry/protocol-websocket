# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/websocket/coder/json"

describe Protocol::WebSocket::Coder::JSON do
	let(:buffer) {'{"hello":"world"}'}
	let(:object) {{hello: "world"}}
	
	it "parses object keys as symbols" do
		expect(subject.parse(buffer)).to be == object
	end
	
	it "generates JSON" do
		expect(subject.generate(object)).to be == buffer
	end
end
