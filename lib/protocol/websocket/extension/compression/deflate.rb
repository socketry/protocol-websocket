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
				class Deflate
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
					
					def initialize(parent, level: Zlib::DEFAULT_COMPRESSION, memory_level: Zlib::DEF_MEM_LEVEL, strategy: Zlib::DEFAULT_STRATEGY, window_bits: 15, context_takeover: true, **options)
						@parent = parent
						
						@deflate = nil
						
						@compression_level = level
						@memory_level = memory_level
						@strategy = strategy
						
						@window_bits = window_bits
						@context_takeover = context_takeover
					end
					
					def text_message(buffer, compress: true, **options)
						buffer = self.deflate(buffer)
						
						frame = @parent.text_message(buffer, **options)
						
						frame.flags |= Frame::RSV1
						
						return frame
					end
					
					def binary_message(buffer, compress: false, **options)
						message = self.deflate(buffer)
						
						frame = parent.binary_message(buffer, **options)
						
						frame.flags |= Frame::RSV1
						
						return frame
					end
					
					private
					
					def deflate(buffer)
						deflate = @deflate || Zlib::Deflate.new(@level, -@window_bits, @memory_level, @strategy)
						
						if @context_takeover
							@deflate = deflate
						end
						
						return @deflate.deflate(buffer, Zlib::SYNC_FLUSH)[0...-4]
					end
				end
			end
		end
	end
end