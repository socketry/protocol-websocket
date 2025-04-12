# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2025, by Samuel Williams.
# Copyright, 2019, by Soumya.
# Copyright, 2021, by Aurora Nockert.
# Copyright, 2025, by Taleh Zaliyev.

require_relative "error"

module Protocol
	module WebSocket
		class Frame
			include Comparable
			
			RSV1 = 0b0100
			RSV2 = 0b0010
			RSV3 = 0b0001
			RESERVED = RSV1 | RSV2 | RSV3
			
			OPCODE = 0
						
			# @parameter length [Integer] The length of the payload, or nil if the header has not been read yet.
			# @parameter mask [Boolean | String] An optional 4-byte string which is used to mask the payload.
			def initialize(finished = true, payload = nil, flags: 0, opcode: self.class::OPCODE, mask: false)
				if mask == true
					mask = SecureRandom.bytes(4)
				end
				
				@finished = finished
				@flags = flags
				@opcode = opcode
				@mask = mask
				@length = payload&.bytesize
				@payload = payload
			end
			
			def flag?(value)
				@flags & value != 0
			end
			
			def <=> other
				to_ary <=> other.to_ary
			end
			
			def to_ary
				[@finished, @flags, @opcode, @mask, @length, @payload]
			end
			
			def control?
				@opcode & 0x8 != 0
			end
			
			# @returns [Boolean] if the frame contains data.
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
			attr_accessor :flags
			attr_accessor :opcode
			attr_accessor :mask
			attr_accessor :length
			attr_accessor :payload
			
			if IO.const_defined?(:Buffer) && IO::Buffer.respond_to?(:for) && IO::Buffer.method_defined?(:xor!)
				private def mask_xor(data, mask)
					buffer = data.dup
					mask_buffer = IO::Buffer.for(mask)
					
					IO::Buffer.for(buffer) do |buffer|
						buffer.xor!(mask_buffer)
					end
					
					return buffer
				end
			else
				warn "IO::Buffer not available, falling back to slow implementation of mask_xor!"
				private def mask_xor(data, mask)
					result = String.new(encoding: Encoding::BINARY)
						
					for i in 0...data.bytesize do
						result << (data.getbyte(i) ^ mask.getbyte(i % 4))
					end
					
					return result
				end
			end
			
			def pack(data = "")
				length = data.bytesize
				
				if length.bit_length > 63
					raise ProtocolError, "Frame length #{@length} bigger than allowed maximum!"
				end
				
				if @mask
					@payload = mask_xor(data, mask)
					@length = length
				else
					@payload = data
					@length = length
				end
				
				return self
			end
			
			def unpack
				if @mask and !@payload.empty?
					return mask_xor(@payload, @mask)
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
				flags = (byte & 0b0111_0000) >> 4
				opcode = byte & 0b0000_1111
				
				if (0x3 .. 0x7).include?(opcode)
					raise ProtocolError, "Non-control opcode = #{opcode} is reserved!"
				elsif (0xB .. 0xF).include?(opcode)
					raise ProtocolError, "Control opcode = #{opcode} is reserved!"
				end
				
				return finished, flags, opcode
			end
			
			def self.read(finished, flags, opcode, stream, maximum_frame_size)
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
					length = buffer.unpack("n").first
				elsif length == 127
					buffer = stream.read(8) or raise EOFError, "Could not read length!"
					length = buffer.unpack("Q>").first
				end
				
				if length > maximum_frame_size
					raise ProtocolError, "Invalid payload length: #{length} > #{maximum_frame_size}!"
				end
				
				if mask
					mask = stream.read(4) or raise EOFError, "Could not read mask!"
				end
				
				payload = stream.read(length) or raise EOFError, "Could not read payload!"
				
				if payload.bytesize != length
					raise EOFError, "Incorrect payload length: #{length} != #{payload.bytesize}!"
				end
				
				return self.new(finished, payload, flags: flags, opcode: opcode, mask: mask)
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
					(@finished ? 0b1000_0000 : 0) | (@flags << 4) | @opcode,
					(@mask ? 0b1000_0000 : 0) | short_length,
				].pack("CC")
				
				if short_length == 126
					buffer << [@length].pack("n")
				elsif short_length == 127
					buffer << [@length].pack("Q>")
				end
				
				buffer << @mask if @mask
				
				stream.write(buffer)
				stream.write(@payload)
			end
		end
	end
end
