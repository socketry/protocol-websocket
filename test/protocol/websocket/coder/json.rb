# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/websocket/coder/json"

describe Protocol::WebSocket::Coder::JSON do
	let(:buffer) {'{"hello":"world"}'}
	let(:object) {{hello: "world"}}
	let(:coder) {subject.new}
	
	it "parses object keys as symbols" do
		expect(coder.parse(buffer)).to be == object
	end
	
	it "generates JSON" do
		expect(coder.generate(object)).to be == buffer
	end
end
