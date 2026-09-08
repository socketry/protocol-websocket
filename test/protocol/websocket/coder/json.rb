# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2026, by Samuel Williams.

require "protocol/websocket/coder/json"

describe Protocol::WebSocket::Coder::JSON do
	let(:buffer) {'{"hello":"world"}'}
	let(:object) {{"hello" => "world"}}
	
	it "applies parsing options only when parsing" do
		coder = subject.new(parse_options: {symbolize_names: true})
		
		expect(coder.parse(buffer)).to be == {hello: "world"}
		expect(coder.generate(object)).to be == buffer
	end
	
	it "applies generation options only when generating" do
		coder = subject.new(generate_options: {space: " "})
		
		expect(coder.parse(buffer)).to be == object
		expect(coder.generate(object)).to be == '{"hello": "world"}'
	end
end
