# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require "protocol/websocket"

describe Protocol::WebSocket do
	it "has a version number" do
		expect(Protocol::WebSocket::VERSION).to be =~ /^\d+\.\d+\.\d+$/
	end
end
