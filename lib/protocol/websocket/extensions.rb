# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require_relative 'extension/compression'
require_relative 'headers'

module Protocol
	module WebSocket
		module Extensions
			def self.parse(headers)
				return to_enum(:parse, headers) unless block_given?
				
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
							
							options = klass.accept(arguments, **options)
							
							@accepted << [klass, options]
						end
					end
					
					return @accepted
				end
				
				def apply(connection)
					@accepted.each do |(klass, options)|
						klass.client(connection, **options)
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
							
							if result = klass.negotiate(arguments, **options)
								header, options = result
								
								# The extension is accepted and no further offers will be considered:
								named.delete(name)
								
								yield header if block_given?
								
								@accepted << [klass, options]
							end
						end
					end
					
					return @accepted
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
