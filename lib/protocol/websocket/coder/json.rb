require 'json'

module Protocol
	module WebSocket
		module Coder
			class JSON
				def initialize(**options)
					@options = options
				end
				
				def parse(buffer)
					::JSON.parse(buffer, **@options)
				end
				
				def generate(object)
					::JSON.generate(object, **@options)
				end
				
				DEFAULT = new(symbolize_names: true)
			end
		end
	end
end
