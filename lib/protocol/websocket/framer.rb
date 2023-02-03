# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require_relative 'frame'

require_relative 'continuation_frame'
require_relative 'text_frame'
require_relative 'binary_frame'
require_relative 'close_frame'
require_relative 'ping_frame'
require_relative 'pong_frame'

module Protocol
	module WebSocket
		# HTTP/2 frame type mapping as defined by the spec.
		FRAMES = {
			0x0 => ContinuationFrame,
			0x1 => TextFrame,
			0x2 => BinaryFrame,
			0x8 => CloseFrame,
			0x9 => PingFrame,
			0xA => PongFrame,
		}.freeze
		
		# The maximum allowed frame size in bytes.
		MAXIMUM_ALLOWED_FRAME_SIZE = 2**63
		
		# Wraps an underlying {Async::IO::Stream} for reading and writing binary data into structured frames.
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
			
			# Read a frame from the underlying stream.
			# @returns [Frame] 
			def read_frame(maximum_frame_size = MAXIMUM_ALLOWED_FRAME_SIZE)
				# Read the header:
				finished, flags, opcode = read_header
				
				# Read the frame:
				klass = @frames[opcode] || Frame
				frame = klass.read(finished, flags, opcode, @stream, maximum_frame_size)
				
				return frame
			end
			
			def write_frame(frame)
				frame.write(@stream)
			end
			
			def read_header
				if buffer = @stream.read(1) and buffer.bytesize == 1
					return Frame.parse_header(buffer)
				end
				
				raise EOFError, "Could not read frame header!"
			end
		end
	end
end
