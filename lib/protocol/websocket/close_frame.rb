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
					[nil, ""]
				when 1
					raise ProtocolError, "invalid close frame length!"
				else
					code, reason = *data.unpack(FORMAT)
					
					case code
					when 0 .. 999, 1005 .. 1006, 1015, 5000 .. 0xFFFF
						raise ProtocolError, "invalid close code!"
					when 1004, 1016 .. 2999
						raise ProtocolError, "reserved close code!"
					end
					
					reason.force_encoding(Encoding::UTF_8)
					
					unless reason.valid_encoding?
						raise ProtocolError, "invalid UTF-8 in close reason!"
					end
					
					[code, reason]
				end
			end
			
			def pack(code, reason)
				if code
					unless reason.encoding == Encoding::UTF_8
						reason = reason.encode(Encoding::UTF_8)
					end
					
					super [code, reason].pack(FORMAT)
				else
					super String.new(encoding: Encoding::BINARY)
				end
			end
			
			def apply(connection)
				connection.receive_close(self)
			end
		end
	end
end
