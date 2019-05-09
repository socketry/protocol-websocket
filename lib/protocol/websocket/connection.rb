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

require_relative 'framer'

module Protocol
	module WebSocket
		class Connection
			def initialize(framer)
				@framer = framer
				@state = :open
				@frames = []
			end
			
			attr :framer
			
			# Buffered frames which form part of a complete message.
			attr_accessor :frames
			
			def closed?
				@state == :closed
			end
			
			def close
				send_close
				
				@framer.close
			end
			
			def read_frame
				frame = @framer.read_frame
				
				yield frame if block_given?
				
				frame.apply(self)
				
				return frame
			rescue ProtocolError => error
				send_close(error.code, error.message)
				
				raise
			rescue
				send_close(Error::PROTOCOL_ERROR, $!.message)
				
				raise
			end
			
			def write_frame(frame)
				@framer.write_frame(frame)
			end
			
			def receive_text(frame)
				if @frames.empty?
					@frames << frame
				else
					raise ProtocolError, "Received text, but expecting continuation!"
				end
			end
			
			def receive_binary(frame)
				if @frames.empty?
					@frames << frame
				else
					raise ProtocolError, "Received binary, but expecting continuation!"
				end
			end
			
			def receive_continuation(frame)
				if @frames.any?
					@frames << frame
				else
					raise ProtocolError, "Received unexpected continuation!"
				end
			end
			
			def send_text(buffer)
				frame = TextFrame.new
				frame.pack buffer
				
				write_frame(frame)
			end
			
			def send_binary(buffer)
				frame = BinaryFrame.new
				frame.pack buffer
				
				write_frame(frame)
			end
			
			def send_close(code = 0, message = nil)
				frame = CloseFrame.new
				frame.pack(code, message)
				
				write_frame(frame)
				
				@state = :closed
			end
			
			def receive_close(frame)
				@state = :closed
				
				code, message = frame.unpack
				
				if code and code != Error::NO_ERROR
					raise CloseError.new message, code
				end
			end
			
			def send_ping(data)
				if @state != :closed
					frame = PingFrame.new
					frame.pack data
					
					write_frame(frame)
				else
					raise ProtocolError, "Cannot send ping in state #{@state}"
				end
			end
			
			def open!
				@state = :open
				
				return self
			end
			
			def receive_ping(frame)
				if @state != :closed
					write_frame(frame.reply)
				else
					raise ProtocolError, "Cannot receive ping in state #{@state}"
				end
			end
			
			def receive_frame(frame)
				warn "Unhandled frame #{frame.inspect}"
			end
			
			# @return [Array<Frame>] sequence of frames, the first being either text or binary, optionally followed by a number of continuation frames.
			def next_message
				@framer.flush
				
				while read_frame
					if @frames.last&.finished?
						frames = @frames
						@frames = []
						
						return frames
					end
				end
			end
		end
	end
end
