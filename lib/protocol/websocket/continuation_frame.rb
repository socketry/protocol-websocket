# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'frame'

module Protocol
	module WebSocket
		class ContinuationFrame < Frame
			OPCODE = 0x0
			
			def apply(connection)
				connection.receive_continuation(self)
			end
		end
	end
end
