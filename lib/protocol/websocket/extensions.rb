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

require_relative 'extension/compression'
require_relative 'headers'

module Protocol
	module WebSocket
		module Extensions
			def self.parse(headers)
				return to_enum(:parse) unless block_given?
				
				headers.each do |header|
					name, *arguments = header.split(/\s*;\s*/)
					
					arguments = arguments.map do |argument|
						argument.split('=', 2)
					end
					
					yield name, arguments
				end
			end
			
			class Client
				def self.default
					self.new([
						[Extension::Compression, {}]
					])
				end
				
				def initialize(extensions = [])
					@extensions = extensions
					@accepted = []
				end
				
				attr :extensions
				attr :accepted
				
				def named
					@extensions.map do |extension|
						[extension.first::NAME, extension]
					end.to_h
				end
				
				def offer
					@extensions.each do |extension, options|
						if header = extension.offer(**options)
							yield header
						end
					end
				end
				
				def accept(headers)
					named = self.named
					
					# Each response header should map to at least one extension.
					Extensions.parse(headers) do |name, arguments|
						if extension = named.delete(name)
							klass, options = extension
							
							klass.accept(arguments, **options)
							
							@accepted << [klass, options]
						end
					end
				end
				
				def apply(connection)
					@accepted.each do |(klass, options)|
						klass.server(connection, **options)
					end
				end
			end
			
			class Server
				def self.default
					self.new([
						[Extension::Compression, {}]
					])
				end
				
				def initialize(extensions)
					@extensions = extensions
					@accepted = []
				end
				
				attr :extensions
				attr :accepted
				
				def named
					@extensions.map do |extension|
						[extension.first::NAME, extension]
					end.to_h
				end
				
				def accept(headers)
					extensions = []
					
					named = self.named
					response = []
					
					# Each response header should map to at least one extension.
					Extensions.parse(headers) do |name, arguments|
						if extension = named[name]
							klass, options = extension
							
							if header = klass.negotiate(arguments, **options)
								# The extension is accepted and no further offers will be considered:
								named.delete(name)
								
								yield header
								
								@accepted << [klass, options]
							end
						end
					end
					
					return headers
				end
				
				def apply(connection)
					@accepted.reverse_each do |(klass, options)|
						klass.server(connection, **options)
					end
				end
			end
		end
	end
end
