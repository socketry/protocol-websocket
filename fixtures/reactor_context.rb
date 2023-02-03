# frozen_string_literal: true

# Released under the MIT License.
# Copyright, 2022-2023, by Samuel Williams.

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
