# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2019-2023, by Samuel Williams.

require 'protocol/http/error'

module Protocol
	module WebSocket
		# Status codes as defined by <https://tools.ietf.org/html/rfc6455#section-7.4.1>.
		class Error < HTTP::Error
			# Indicates a normal closure, meaning that the purpose for which the connection was established has been fulfilled.
			NO_ERROR = 1000
			
			# Indicates that an endpoint is "going away", such as a server going down or a browser having navigated away from a page.
			GOING_AWAY = 1001
			
			# Indicates that an endpoint is terminating the connection due to a protocol error.
			PROTOCOL_ERROR = 1002
			
			# Indicates that an endpoint is terminating the connection because it has received a type of data it cannot accept.
			INVALID_DATA = 1003
			
			# There are other status codes but most of them are "implementation specific".
		end
		
		# Raised by stream or connection handlers, results in GOAWAY frame
		# which signals termination of the current connection. You *cannot*
		# recover from this exception, or any exceptions subclassed from it.
		class ProtocolError < Error
			def initialize(message, code = PROTOCOL_ERROR)
				super(message)
				
				@code = code
			end
			
			attr :code
		end
		
		# The connection was closed, maybe unexpectedly.
		class ClosedError < ProtocolError
		end
		
		# When the frame payload does not match expectations.
		class FrameSizeError < ProtocolError
		end
	end
end
