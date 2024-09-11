# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require "protocol/websocket/headers"

describe Protocol::WebSocket::Headers::Nounce do
	with "#generate_key" do
		let(:key) {subject.generate_key}
		
		it "can generate valid key length" do
			expect(key.length).to be == 24
		end
	end
	
	with "#accept_digest" do
		# Taken from https://tools.ietf.org/html/rfc6455#section-1.2
		let(:key) {"dGhlIHNhbXBsZSBub25jZQ=="}
		let(:digest) {subject.accept_digest(key)}
		
		it "can validate digest" do
			expect(digest).to be == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
		end
	end
end
