# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
# 
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
# 
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
# 
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

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
