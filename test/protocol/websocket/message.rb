# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2023, by Samuel Williams.

require 'protocol/websocket/message'

describe Protocol::WebSocket::Message do
	let(:buffer) {"Hello World!"}
	let(:message) {subject.new(buffer)}
	
	it "can round-trip basic object" do
		expect(message.to_str).to be == buffer
	end
	
	with "a JSON encoded message" do
		let(:value) {{hello: "world"}}
		let(:message) {subject.generate(value)}
		
		with "#parse" do
			it "can parse JSON" do
				expect(message.parse).to be == {hello: "world"}
			end
		end
		
		with "#to_h" do
			it "can convert to hash" do
				expect(message.to_h).to be == {hello: "world"}
			end
		end
	end
end
