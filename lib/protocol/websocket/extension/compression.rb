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

require 'zlib'
require_relative 'compression/inflate'
require_relative 'compression/deflate'

module Protocol
	module WebSocket
		module Extension
			module Compression
				NAME = 'permessage-deflate'
				
				def self.offer(client_window_bits: true, server_window_bits: true, client_no_context_takeover: false, server_no_context_takeover: false)
					
					header = [NAME]
					
					case client_window_bits
					when 8..15
						header << "client_max_window_bits=#{client_window_bits}"
					when true
						header << 'client_max_window_bits'
					else
						raise ArgumentError, "Invalid local maximum window bits!"
					end
					
					if client_no_context_takeover
						header << 'client_no_context_takeover'
					end
					
					case server_window_bits
					when 8..15
						header << "server_max_window_bits=#{server_window_bits}"
					else
						raise ArgumentError, "Invalid remote maximum window bits!"
					end
					
					if server_no_context_takeover
						header << 'server_no_context_takeover'
					end
					
					return header
				end

				def self.negotiate(arguments, options)
					header = [NAME]
					
					arguments.each do |key, value|
						case key
						when "server_no_context_takeover"
							options[:server_no_context_takeover] = false
							header << key
						when "client_no_context_takeover"
							options[:client_no_context_takeover] = false
							header << key
						when "server_max_window_bits"
							options[:server_max_window_bits] = Integer(value || 15)
						when "client_max_window_bits"
							options[:client_max_window_bits] = Integer(value || 15)
						else
							raise ArgumentError, "Unknown option #{key}!"
						end
					end
					
					return header
				end
				
				def self.server(connection, allowed, **options)
					raise "Unable to use RSV1!" unless allowed.delete(:RSV1)
					
					connection.reader = Inflate.server(connection.reader, **options)
					connection.writer = Deflate.server(connection.writer, **options)
				end
				
				def self.client_accept(arguments, options)
					arguments.each do |key, value|
						case key
						when "server_no_context_takeover"
							options[:server_no_context_takeover] = false
						when "client_no_context_takeover"
							options[:client_no_context_takeover] = false
						when "server_max_window_bits"
							options[:server_max_window_bits] = Integer(value || 15)
						when "client_max_window_bits"
							options[:client_max_window_bits] = Integer(value || 15)
						else
							raise ArgumentError, "Unknown option #{key}!"
						end
					end
				end
				
				def self.client(connection, allowed, **options)
					raise "Unable to use RSV1!" unless allowed.delete(:RSV1)
					
					connection.reader = Inflate.client(connection.reader, **options)
					connection.writer = Deflate.client(connection.writer, **options)
				end
			end
		end
	end
end