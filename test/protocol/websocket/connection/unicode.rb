# Copyright, 2022, by Samuel G. D. Williams. <http://www.codeotaku.com>
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

require 'socket'
require_library 'protocol/websocket/connection'

describe Protocol::WebSocket::Connection do
	let(:sockets) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	let(:client) {Protocol::WebSocket::Framer.new(sockets.first)}
	let(:server) {Protocol::WebSocket::Framer.new(sockets.last)}
	
	let(:connection) {subject.new(server)}
	
	with "invalid unicode text message in 3 fragments" do
		let(:payload1) {"\xce\xba\xe1\xbd\xb9\xcf\x83\xce\xbc\xce\xb5".b}
		let(:payload2) {"\xf4\x90\x80\x80".b}
		let(:payload3) {"\x65\x64\x69\x74\x65\x64".b}
		
		it "fails with protocol error" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(false, payload1))
				client.write_frame(Protocol::WebSocket::ContinuationFrame.new(false, payload2))
				client.write_frame(Protocol::WebSocket::ContinuationFrame.new(true, payload3))
			end
			
			expect do
				connection.read
			end.to raise_exception(Protocol::WebSocket::ProtocolError)
			
			thread.join
		ensure
			client.close
			server.close
		end
	end
end
