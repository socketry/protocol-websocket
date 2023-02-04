# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

require 'json'

require_relative 'message'

module Protocol
	module WebSocket
		class JSONMessage < TextMessage
			def self.wrap(message)
				if message.is_a?(TextMessage)
					self.new(message.buffer)
				end
			end
			
			def self.generate(object)
				self.new(JSON.generate(object))
			end
			
			def parse(symbolize_names: true, **options)
				JSON.parse(@buffer, symbolize_names: symbolize_names, **options)
			end
			
			def to_h
				parse.to_h
			end
		end
	end
end
