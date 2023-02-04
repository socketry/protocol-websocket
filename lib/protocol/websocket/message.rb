# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require_relative 'frame'

module Protocol
	module WebSocket
		class Message
			def initialize(buffer)
				@buffer = buffer
			end
			
			attr :buffer
			
			def size
				@buffer.bytesize
			end
			
			# This can be helpful for writing tests.
			def == other
				@buffer == other.to_str
			end
			
			def to_str
				@buffer
			end
			
			def encoding
				@buffer.encoding
			end
		end
		
		class TextMessage < Message
			def send(connection, **options)
				connection.send_text(@buffer, **options)
			end
		end
		
		class BinaryMessage < Message
			def send(connection, **options)
				connection.send_binary(@buffer, **options)
			end
		end
	end
end
