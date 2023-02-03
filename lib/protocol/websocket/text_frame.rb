# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

require_relative 'frame'
require_relative 'message'

module Protocol
	module WebSocket
		# Implements the text frame for sending and receiving text.
		class TextFrame < Frame
			OPCODE = 0x1
			
			def data?
				true
			end
			
			# Decode the binary buffer into a suitable text message.
			# @parameter buffer [String] The binary data to unpack.
			def read_message(buffer)
				buffer.force_encoding(Encoding::UTF_8)
				
				unless buffer.valid_encoding?
					raise ProtocolError, "invalid UTF-8 in text frame!"
				end
				
				return TextMessage.new(buffer)
			end
			
			# Apply this frame to the specified connection.
			def apply(connection)
				connection.receive_text(self)
			end
		end
	end
end
