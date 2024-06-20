require_relative 'coder/json'

module Protocol
	module WebSocket
		module Coder
			# The default coder for WebSocket messages.
			DEFAULT = JSON::DEFAULT
		end
	end
end
