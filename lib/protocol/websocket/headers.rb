# Copyright, 2019, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'digest/sha1'
require 'securerandom'

module Protocol
	module WebSocket
		module Headers
			# The protocol string used for the `upgrade:` header (HTTP/1) and `:protocol` pseudo-header (HTTP/2).
			PROTOCOL = "websocket".freeze
			
			# These general headers are used to negotiate the connection.
			SEC_WEBSOCKET_PROTOCOL = 'sec-websocket-protocol'.freeze
			SEC_WEBSOCKET_VERSION = 'sec-websocket-version'.freeze
			
			SEC_WEBSOCKET_KEY = 'sec-websocket-key'.freeze
			SEC_WEBSOCKET_ACCEPT = 'sec-websocket-accept'.freeze
			
			GUID = "258EAFA5-E914-47DA-95CA-C5AB0DC85B11"
			
			# Valid for the `SEC_WEBSOCKET_KEY` header.
			def self.generate_key
				SecureRandom.base64(16)
			end
			
			# Valid for the `SEC_WEBSOCKET_ACCEPT` header.
			def self.accept_digest(key)
				Digest::SHA1.base64digest(key + GUID)
			end
		end
	end
end
