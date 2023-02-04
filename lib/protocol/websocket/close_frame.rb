# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.
# Copyright, 2021, by Aurora Nockert.

require_relative 'frame'

module Protocol
	module WebSocket
		class CloseFrame < Frame
			OPCODE = 0x8
			FORMAT = "na*"
			
			def unpack
				data = super
				
				case data.length
				when 0
					[nil, nil]
				when 1
					raise ProtocolError, "Invalid close frame length!"
				else
					code, reason = *data.unpack(FORMAT)
					
					case code
					when 0 .. 999, 1005 .. 1006, 1015, 5000 .. 0xFFFF
						raise ProtocolError, "Invalid close code!"
					when 1004, 1016 .. 2999
						raise ProtocolError, "Reserved close code!"
					end
					
					reason.force_encoding(Encoding::UTF_8)
					
					unless reason.valid_encoding?
						raise ProtocolError, "Invalid UTF-8 in close reason!"
					end
					
					[code, reason]
				end
			end
			
			# If code is missing, reason is ignored.
			def pack(code = nil, reason = nil)
				if code
					if reason and reason.encoding != Encoding::UTF_8
						reason = reason.encode(Encoding::UTF_8)
					end
					
					super([code, reason].pack(FORMAT))
				else
					super()
				end
			end
			
			def apply(connection)
				connection.receive_close(self)
			end
		end
	end
end
