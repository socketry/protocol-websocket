# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

require_relative 'frame'
require_relative 'message'

module Protocol
	module WebSocket
		class BinaryFrame < Frame
			OPCODE = 0x2
			
			def data?
				true
			end
			
			def read_message(buffer)
				return BinaryMessage.new(buffer)
			end
			
			def apply(connection)
				connection.receive_binary(self)
			end
		end
	end
end
