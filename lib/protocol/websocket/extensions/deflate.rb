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

module Protocol
	module WebSocket
		module Extensions
			class Deflate
				DEFAULT_OPTIONS = {
					request_no_context_takeover: false,
					request_max_window_bits: 11,
					no_context_takeover: false,
					max_window_bits: 11,
					memory_level: 4
				}
				
				TRAILER = [0x00, 0x00, 0xff, 0xff].pack('C*')
				
				def initialize(level: Zlib::DEFAULT_COMPRESSION, memory_level: Zlib::DEF_MEM_LEVEL, strategy: Zlib::DEFAULT_STRATEGY, no_context_takeover: false, maximum_window_bits: 10, request_no_context_takeover: false, request_maximum_window_bits: nil)
					@inflate = nil
					@deflate = nil
					
					@level = level
					@mem_level = memory_level
					@strategy = stragegy
					
					@no_context_takeover = no_context_takeover
					@maximum_window_bits = maximum_window_bits
					@request_no_context_takeover = request_no_context_takeover
					@request_maximum_window_bits = request_maximum_window_bits
				end
				
				def unpack(frame)
					if frame.rsv1?
						inflate = get_inflate
						
						message.data = inflate.inflate(message.data) + inflate.inflate(TRAILER)
						
						free(inflate) unless @inflate
						message
					end
				end
				
				def unpack(frame)
				end
				
				def process_incoming_message(message)
					return message unless message.rsv1

					inflate = get_inflate

					message.data = inflate.inflate(message.data) +
												 inflate.inflate([0x00, 0x00, 0xff, 0xff].pack('C*'))

					free(inflate) unless @inflate
					message
				end

				def process_outgoing_message(message)
					deflate = get_deflate

					message.data = deflate.deflate(message.data, Zlib::SYNC_FLUSH)[0...-4]
					message.rsv1 = true

					free(deflate) unless @deflate
					message
				end
				
				def free(codec)
					return if codec.nil?
					codec.finish rescue nil
					codec.close
				end
				
				def inflate
					return @inflate if @inflate
					
					window_bits = [@peer_window_bits, MIN_WINDOW_BITS].max
					inflate = Zlib::Inflate.new(-window_bits)
					
					if @peer_context_takeover
						@inflate = inflate
					end
					
					return inflate
				end
				
				def deflate
					# Reuse the deflate if it was allowed:
					return @deflate if @deflate
					
					window_bits = [@own_window_bits, MIN_WINDOW_BITS].max
					deflate = Zlib::Deflate.new(@level, -window_bits, @mem_level, @strategy)
					
					if @own_context_takeover
						@deflate = deflate
					end
					
					return deflate
				end
			end
		end
	end
end


