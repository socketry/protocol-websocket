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

require 'socket'
require_library 'protocol/websocket/connection'

describe Protocol::WebSocket::Connection do
	let(:sockets) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	
	let(:client) {Protocol::WebSocket::Framer.new(sockets.first)}
	let(:server) {Protocol::WebSocket::Framer.new(sockets.last)}
	
	let(:connection) {subject.new(server)}
	
	it "doesn't generate mask by default" do
		expect(connection.mask).to be == nil
	end
	
	with "masked connection" do
		let(:connection) {subject.new(server, mask: true)}
		
		it "generates valid mask" do
			frame = connection.send_text("Hello World")
			expect(frame.mask).to be(:kind_of?, String)
			expect(frame.mask.bytesize).to be == 4
		end
	end
	
	with "fragmented text frames" do
		let(:text_frame) do
			Protocol::WebSocket::TextFrame.new(false).tap{|frame| frame.pack("Hello ")}
		end
		
		let(:ping_frame) do
			Protocol::WebSocket::PingFrame.new.tap{|frame| frame.pack("Yo")}
		end
		
		let(:continuation_frame) do
			Protocol::WebSocket::ContinuationFrame.new(true).tap{|frame| frame.pack("world!")}
		end
		
		it "can reconstruct fragmented message" do
			client.write_frame(text_frame)
			client.write_frame(ping_frame)
			client.write_frame(continuation_frame)
			
			message = connection.read
			expect(message).to be == "Hello world!"
			expect(message.encoding).to be == Encoding::UTF_8
			
			expect(client.read_frame).to be == ping_frame.reply
		end
	end
	
	with "a text messages" do
		it "can send and receive text frames" do
			connection.write("Hello World".encode(Encoding::UTF_8))
			
			expect(client.read_frame).to be(:kind_of?, Protocol::WebSocket::TextFrame)
		end
	end
	
	with "a binary messages" do
		it "can send and receive binary frames" do
			connection.write("Hello World".encode(Encoding::BINARY))
			
			expect(client.read_frame).to be(:kind_of?, Protocol::WebSocket::BinaryFrame)
		end
	end
	
	with "different message lengths" do
		it "can handle a short message (<126)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 15)})
			end
			
			message = connection.read
			expect(message.size).to be == 15
			
			thread.join
		end

		it "can handle a medium message (<65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 60_000)})
			end
			
			message = connection.read
			expect(message.size).to be == 60_000
			
			thread.join
		end

		it "can handle large message (>65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 90_000)})
			end
			
			message = connection.read
			expect(message.size).to be == 90_000
			
			thread.join
		end
	end
	
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
