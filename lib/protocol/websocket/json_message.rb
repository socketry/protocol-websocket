# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require_relative 'message'

warn "Protocol::WebSocket::JSONMessage is deprecated. Use Protocol::WebSocket::TextMessage instead."

module Protocol
	module WebSocket
		# @deprecated Use {TextMessage} instead.
		class JSONMessage < TextMessage
			def self.wrap(message)
				message
			end
			
			def self.generate(object)
				self.new(JSON.generate(object))
			end
		end
	end
end
