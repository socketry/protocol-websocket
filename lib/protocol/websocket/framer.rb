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

require_relative 'continuation_frame'
require_relative 'text_frame'
require_relative 'binary_frame'
require_relative 'close_frame'
require_relative 'ping_frame'
require_relative 'pong_frame'

module Protocol
	module WebSocket
		# HTTP/2 frame type mapping as defined by the spec
		FRAMES = {
			0x0 => ContinuationFrame,
			0x1 => TextFrame,
			0x2 => BinaryFrame,
			0x8 => CloseFrame,
			0x9 => PingFrame,
			0xA => PongFrame,
		}.freeze
		
		MAXIMUM_ALLOWED_FRAME_SIZE = 2**63
		
		class Framer
			def initialize(stream, frames = FRAMES)
				@stream = stream
				@frames = frames
			end
			
			def close
				@stream.close
			end
			
			def flush
				@stream.flush
			end
			
			def read_frame(maximum_frame_size = MAXIMUM_ALLOWED_FRAME_SIZE)
				# Read the header:
				finished, opcode = read_header
				
				# Read the frame:
				klass = @frames[opcode] || Frame
				frame = klass.read(finished, opcode, @stream, maximum_frame_size)
				
				return frame
			end
			
			def write_frame(frame)
				frame.write(@stream)
			end
			
			def read_header
				if buffer = @stream.read(1)
					return Frame.parse_header(buffer)
				end
				
				raise EOFError, "Could not read frame header!"
			end
		end
	end
end
