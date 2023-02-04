# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'protocol/websocket/json_message'

describe Protocol::WebSocket::JSONMessage do
	let(:object) {{text: "Hello World", number: 42}}
	let(:message) {subject.generate(object)}
	
	it "can round-trip basic object" do
		expect(message.parse).to be == object
	end
	
	with '#wrap' do
		let(:text_message) {Protocol::WebSocket::TextMessage.new(JSON.dump(object))}
		let(:message) {subject.wrap(text_message)}
		
		it 'can wrap a text message' do
			expect(message.parse).to be == object
		end
	end
	
	with '#to_h' do
		it 'can be converted to a hash' do
			expect(message.to_h).to be == object
		end
	end
end
