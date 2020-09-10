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

require 'protocol/websocket/connection'

RSpec.describe Protocol::WebSocket::Connection do
	let(:sockets) {Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)}
	
	let(:client) {Protocol::WebSocket::Framer.new(sockets.first)}
	let(:server) {Protocol::WebSocket::Framer.new(sockets.last)}
	
	subject {described_class.new(server)}
	
	it "doesn't generate mask by default" do
		expect(subject.mask).to be nil
	end
	
	context "with masked connection" do
		subject {described_class.new(server, mask: true)}
		
		it "generates valid mask" do
			frame = subject.send_text("Hello World")
			expect(frame.mask).to be_a String
			expect(frame.mask.bytesize).to be == 4
		end
	end
	
	context "with fragmented text frames" do
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
			
			message = subject.read
			expect(message).to be == "Hello world!"
			expect(message.encoding).to be == Encoding::UTF_8
			
			expect(client.read_frame).to be == ping_frame.reply
		end
	end
	
	context "text messages" do
		it "can send and receive text frames" do
			subject.write("Hello World".encode(Encoding::UTF_8))
			
			expect(client.read_frame).to be_kind_of(Protocol::WebSocket::TextFrame)
		end
	end
	
	context "binary messages" do
		it "can send and receive binary frames" do
			subject.write("Hello World".encode(Encoding::BINARY))
			
			expect(client.read_frame).to be_kind_of(Protocol::WebSocket::BinaryFrame)
		end
	end
	
	context "message length" do
		it "can handle a short message (<126)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 15)})
			end
			
			message = subject.read
			expect(message.size).to be == 15
			
			thread.join
		end

		it "can handle a medium message (<65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 60_000)})
			end
			
			message = subject.read
			expect(message.size).to be == 60_000
			
			thread.join
		end

		it "can handle large message (>65k)" do
			thread = Thread.new do
				client.write_frame(Protocol::WebSocket::TextFrame.new(true).tap{|frame| frame.pack("a" * 90_000)})
			end
			
			message = subject.read
			expect(message.size).to be == 90_000
			
			thread.join
		end
	end
end
