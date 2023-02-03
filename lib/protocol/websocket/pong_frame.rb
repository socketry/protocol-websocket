# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'frame'

module Protocol
	module WebSocket
		class PongFrame < Frame
			OPCODE = 0xA
			
			# Apply this frame to the specified connection.
			def apply(connection)
				connection.receive_pong(self)
			end
		end
	end
end
