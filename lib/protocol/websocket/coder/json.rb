# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2024-2026, by Samuel Williams.

require "json"

module Protocol
	module WebSocket
		module Coder
			# A JSON coder that uses the standard JSON library.
			class JSON
				# Initialize a new JSON coder.
				# @parameter parse_options [Hash] Options to pass to the JSON library when parsing.
				# @parameter generate_options [Hash] Options to pass to the JSON library when generating.
				def initialize(parse_options: {}, generate_options: {})
					@parse_options = parse_options
					@generate_options = generate_options
				end
				
				# Parse a JSON buffer into an object.
				def parse(buffer)
					::JSON.parse(buffer, **@parse_options)
				end
				
				# Generate a JSON buffer from an object.
				def generate(object)
					::JSON.generate(object, **@generate_options)
				end
				
				# The default JSON coder. This coder will symbolize names.
				DEFAULT = new(parse_options: {symbolize_names: true})
			end
		end
	end
end
