# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2024, by Samuel Williams.

require "socket"

module Protocol
	module WebSocket
		AWebSocketFrame = Sus::Shared("a websocket frame") do
			require "protocol/websocket/framer"
			
			let(:sockets) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
			
			let(:client) {Protocol::WebSocket::Framer.new(sockets.first)}
			let(:server) {Protocol::WebSocket::Framer.new(sockets.last)}
			
			it "can send frame over sockets" do
				server.write_frame(frame)
				
				transmitted_frame = client.read_frame
				
				expect(transmitted_frame).to be == frame
			end
		end
	end
end
