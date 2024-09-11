# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024, by Samuel Williams.

require "json"

module Protocol
	module WebSocket
		module Coder
			# A JSON coder that uses the standard JSON library.
			class JSON
				def initialize(**options)
					@options = options
				end
				
				# Parse a JSON buffer into an object.
				def parse(buffer)
					::JSON.parse(buffer, **@options)
				end
				
				# Generate a JSON buffer from an object.
				def generate(object)
					::JSON.generate(object, **@options)
				end
				
				# The default JSON coder. This coder will symbolize names.
				DEFAULT = new(symbolize_names: true)
			end
		end
	end
end
