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

require 'protocol/websocket/headers'

describe Protocol::WebSocket::Headers::Nounce do
	with '#generate_key' do
		let(:key) {subject.generate_key}
		
		it "can generate valid key length" do
			expect(key.length).to be == 24
		end
	end
	
	with '#accept_digest' do
		# Taken from https://tools.ietf.org/html/rfc6455#section-1.2
		let(:key) {"dGhlIHNhbXBsZSBub25jZQ=="}
		let(:digest) {subject.accept_digest(key)}
		
		it "can validate digest" do
			expect(digest).to be == "s3pPLMBiTxaQ9kYGzzhZRbK+xOo="
		end
	end
end
