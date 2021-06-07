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

require_relative 'error'

module Protocol
	module WebSocket
		class Frame
			include Comparable
			
			OPCODE = 0
			
			# @parameter length [Integer] The length of the payload, or nil if the header has not been read yet.
			# @parameter mask [Boolean | String] An optional 4-byte string which is used to mask the payload.
			def initialize(finished = true, payload = nil, opcode: self.class::OPCODE, mask: false)
				if mask == true
					mask = SecureRandom.bytes(4)
				end
				
				@finished = finished
				@opcode = opcode
				@mask = mask
				@length = payload&.bytesize
				@payload = payload
			end
			
			def <=> other
				to_ary <=> other.to_ary
			end
			
			def to_ary
				[@finished, @opcode, @mask, @length, @payload]
			end
			
			def control?
				@opcode & 0x8 != 0
			end
			
			def data?
				false
			end
			
			def finished?
				@finished == true
			end
			
			def continued?
				@finished == false
			end
			
			# The generic frame header uses the following binary representation:
			#
			#  0                   1                   2                   3
			#  0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
			# +-+-+-+-+-------+-+-------------+-------------------------------+
			# |F|R|R|R| opcode|M| Payload len |    Extended payload length    |
			# |I|S|S|S|  (4)  |A|     (7)     |             (16/64)           |
			# |N|V|V|V|       |S|             |   (if payload len==126/127)   |
			# | |1|2|3|       |K|             |                               |
			# +-+-+-+-+-------+-+-------------+ - - - - - - - - - - - - - - - +
			# |     Extended payload length continued, if payload len == 127  |
			# + - - - - - - - - - - - - - - - +-------------------------------+
			# |                               |Masking-key, if MASK set to 1  |
			# +-------------------------------+-------------------------------+
			# | Masking-key (continued)       |          Payload Data         |
			# +-------------------------------- - - - - - - - - - - - - - - - +
			# :                     Payload Data continued ...                :
			# + - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - +
			# |                     Payload Data continued ...                |
			# +---------------------------------------------------------------+
			
			attr_accessor :finished
			attr_accessor :opcode
			attr_accessor :mask
			attr_accessor :length
			attr_accessor :payload
			
			def pack(data)
				length = data.bytesize
				
				if length.bit_length > 63
					raise ProtocolError, "Frame length #{@length} bigger than allowed maximum!"
				end

				if @mask
					@payload = String.new(encoding: Encoding::BINARY)
					
					for i in 0...data.bytesize do
						@payload << (data.getbyte(i) ^ mask.getbyte(i % 4))
					end
					
					@length = length
				else
					@payload = data
					@length = length
				end
			end
			
			def unpack
				if @mask and !@payload.empty?
					data = String.new(encoding: Encoding::BINARY)
					
					for i in 0...@payload.bytesize do
						data << (@payload.getbyte(i) ^ @mask.getbyte(i % 4))
					end
					
					return data
				else
					return @payload
				end
			end
			
			def apply(connection)
				connection.receive_frame(self)
			end
			
			def self.parse_header(buffer)
				byte = buffer.unpack("C").first
				
				finished = (byte & 0b1000_0000 != 0)
				rsv = byte & 0b0111_0000
				opcode = byte & 0b0000_1111

				unless rsv == 0
					raise ProtocolError, "RSV = #{rsv >> 4}, expected 0!"
				end

				if (0x3 .. 0x7).include?(opcode)
					raise ProtocolError, "non-control opcode = #{opcode} is reserved!"
				elsif (0xB .. 0xF).include?(opcode)
					raise ProtocolError, "control opcode = #{opcode} is reserved!"
				end
				
				return finished, opcode
			end
			
			def self.read(finished, opcode, stream, maximum_frame_size)
				buffer = stream.read(1) or raise EOFError, "Could not read header!"
				byte = buffer.unpack("C").first
				
				mask = (byte & 0b1000_0000 != 0)
				length = byte & 0b0111_1111
				
				if opcode & 0x8 != 0
					if length > 125
						raise ProtocolError, "Invalid control frame payload length: #{length} > 125!"
					elsif !finished
						raise ProtocolError, "Fragmented control frame!"
					end
				end
				
				if length == 126
					buffer = stream.read(2) or raise EOFError, "Could not read length!"
					length = buffer.unpack('n').first
				elsif length == 127
					buffer = stream.read(8) or raise EOFError, "Could not read length!"
					length = buffer.unpack('Q>').first
				end
				
				if length > maximum_frame_size
					raise ProtocolError, "Invalid payload length: #{@length} > #{maximum_frame_size}!"
				end
				
				if mask
					mask = stream.read(4) or raise EOFError, "Could not read mask!"
				end
				
				payload = stream.read(length) or raise EOFError, "Could not read payload!"
				
				if payload.bytesize != length
					raise EOFError, "Incorrect payload length: #{@length} != #{@payload.bytesize}!"
				end
				
				return self.new(finished, payload, opcode: opcode, mask: mask)
			end
			
			def write(stream)
				buffer = String.new(encoding: Encoding::BINARY)
				
				if @payload&.bytesize != @length
					raise ProtocolError, "Invalid payload length: #{@length} != #{@payload.bytesize} for #{self}!"
				end
				
				if @mask and @mask.bytesize != 4
					raise ProtocolError, "Invalid mask length!"
				end
				
				if length <= 125
					short_length = length
				elsif length.bit_length <= 16
					short_length = 126
				else
					short_length = 127
				end
				
				buffer << [
					(@finished ? 0b1000_0000 : 0) | @opcode,
					(@mask ? 0b1000_0000 : 0) | short_length,
				].pack('CC')
				
				if short_length == 126
					buffer << [@length].pack('n')
				elsif short_length == 127
					buffer << [@length].pack('Q>')
				end
				
				buffer << @mask if @mask
				
				stream.write(buffer)
				stream.write(@payload)
			end
		end
	end
end
