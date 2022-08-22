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
