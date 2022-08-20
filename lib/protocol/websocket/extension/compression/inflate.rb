# Copyright, 2021, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'zlib'

module Protocol
	module WebSocket
		module Extension
			module Compression
				class Inflate
					def self.client(parent, client_window_bits: 15, client_no_context_takeover: false, **options)
						self.new(parent,
							window_bits: client_window_bits,
							context_takeover: !client_no_context_takeover,
							**options
						)
					end
					
					def self.server(parent, server_window_bits: 15, server_no_context_takeover: false, **options)
						self.new(parent,
							window_bits: server_window_bits,
							context_takeover: !server_no_context_takeover,
							**options
						)
					end
					
					TRAILER = [0x00, 0x00, 0xff, 0xff].pack('C*')
					
					def initialize(parent, context_takeover: true, window_bits: 15)
						@parent = parent
						
						@inflate = nil
						
						@window_bits = window_bits
						@context_takeover = context_takeover
					end
					
					def read_message(frames, **options)
						buffer = @parent.read_message(frames, **options)
						
						frame = frames.first
						
						if frame.flags & Frame::RSV1
							buffer = self.inflate(buffer)
						end
						
						frame.flags &= ~Frame::RSV1
						
						return buffer
					end
					
					private
					
					def inflate(buffer)
						Console.logger.info(self, "Inflating #{buffer.bytesize} bytes")
						inflate = @inflate || Zlib::Inflate.new(-@window_bits)
						
						if @context_takeover
							@inflate = inflate
						end
						
						return inflate.inflate(buffer + TRAILER)
					end
				end
			end
		end
	end
end
