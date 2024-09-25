# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2024, by Samuel Williams.

require_relative "constants"

module Protocol
	module WebSocket
		module Extension
			module Compression
				class Inflate
					# Client reading from server.
					def self.client(parent, server_max_window_bits: 15, server_no_context_takeover: false, **options)
						self.new(parent,
							window_bits: server_max_window_bits,
							context_takeover: !server_no_context_takeover,
						)
					end
					
					# Server reading from client.
					def self.server(parent, client_max_window_bits: 15, client_no_context_takeover: false, **options)
						self.new(parent,
							window_bits: client_max_window_bits,
							context_takeover: !client_no_context_takeover,
						)
					end
					
					TRAILER = [0x00, 0x00, 0xff, 0xff].pack("C*")
					
					def initialize(parent, context_takeover: true, window_bits: 15)
						@parent = parent
						
						@inflate = nil
						
						# This is handled during negotiation:
						# if window_bits < MINIMUM_WINDOW_BITS
						# 	window_bits = MINIMUM_WINDOW_BITS
						# end
						
						@window_bits = window_bits
						@context_takeover = context_takeover
					end
					
					def to_s
						"#<#{self.class} window_bits=#{@window_bits} context_takeover=#{@context_takeover}>"
					end
					
					attr :window_bits
					attr :context_takeover
					
					def unpack_frames(frames, **options)
						buffer = @parent.unpack_frames(frames, **options)
						
						frame = frames.first
						
						if frame.flag?(Frame::RSV1)
							buffer = self.inflate(buffer)
							frame.flags &= ~Frame::RSV1
						end
						
						return buffer
					end
					
					private
					
					def inflate(buffer)
						inflate = @inflate || Zlib::Inflate.new(-@window_bits)
						
						if @context_takeover
							@inflate = inflate
						end
						
						return inflate.inflate(buffer + TRAILER)
					end
				end
			end
		end
	end
end
