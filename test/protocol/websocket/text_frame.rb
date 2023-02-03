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

require 'a_websocket_frame'
require 'protocol/websocket/text_frame'

describe Protocol::WebSocket::TextFrame do
	let(:frame) {subject.new}
	
	it "contains data" do
		expect(frame).to be(:data?)
	end
	
	it "isn't a control frame" do
		expect(frame).not.to be(:control?)
	end
	
	with "with mask" do
		let(:frame) {subject.new(mask: "abcd").pack("Hello World")}
		
		it_behaves_like AWebSocketFrame
		
		it "encodes binary representation" do
			buffer = StringIO.new
			
			frame.write(buffer)
			
			expect(buffer.string).to be == "\x81\x8Babcd)\a\x0F\b\x0EB4\v\x13\x0E\a"
		end
	end
	
	with "without mask" do
		let(:frame) {subject.new.pack("Hello World")}
		
		it_behaves_like AWebSocketFrame
		
		it "encodes binary representation" do
			buffer = StringIO.new
			
			frame.write(buffer)
			
			expect(buffer.string).to be == "\x81\vHello World"
		end
	end
end
