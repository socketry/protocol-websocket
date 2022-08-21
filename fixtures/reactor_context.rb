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

require 'async'

module ReactorContext
	def run_with_timeout(reactor, timeout = nil, &block)
		result = nil
		timer_task = nil
		
		if timeout
			timer_task = reactor.async(transient: true) do |task|
				# Wait for the timeout, at any point this task might be cancelled if the user code completes:
				task.annotate("Timer task timeout=#{timeout}.")
				task.sleep(timeout)
				
				# The timeout expired, so generate an error:
				buffer = StringIO.new
				reactor.print_hierarchy(buffer)
				
				# Raise an error so it is logged:
				raise Async::TimeoutError, "Run time exceeded timeout #{timeout}s:\n#{buffer.string}"
			end
		end
		
		spec_task = reactor.async do |spec_task|
			spec_task.annotate("running example")
			
			begin
				result = yield(spec_task)
			ensure
				# We are finished, so stop the timer task if it was started:
				timer_task&.stop
			end
			
			# Now stop the entire reactor:
			raise Async::Stop
		end
		
		begin
			timer_task&.wait
			spec_task.wait
		ensure
			spec_task.stop
		end
		
		return result
	end
	
	def reactor
		@reactor
	end
	
	def timeout
		10
	end
	
	def around(&block)
		Sync do |task|
			@reactor = task.reactor
			
			task.annotate(self.class)
			
			run_with_timeout(@reactor, self.timeout) do
				super(&block)
			end
		ensure
			@reactor = nil
		end
	end
end
