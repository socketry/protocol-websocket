def mask_xor_buffer(data, mask)
	buffer = data.dup
	mask_buffer = IO::Buffer.for(mask)

	IO::Buffer.for(buffer) do |buffer|
		buffer.xor!(mask_buffer)
	end

	return buffer
end

def mask_xor_string(data, mask)
	result = String.new(encoding: Encoding::BINARY)

	for i in 0...data.bytesize do
		result << (data.getbyte(i) ^ mask.getbyte(i % 4))
	end

	return result
end

require 'benchmark/ips'
require 'securerandom'

MASK = SecureRandom.bytes(4)
DATA = SecureRandom.bytes(1024 * 1024)

Benchmark.ips do |x|
  # Configure the number of seconds used during
  # the warmup phase (default 2) and calculation phase (default 5)
  x.config(:time => 5, :warmup => 2)

  # These parameters can also be configured this way
  x.time = 5
  x.warmup = 2

	x.report("IO::Buffer") {mask_xor_buffer(DATA, MASK)}
	x.report("String") {mask_xor_string(DATA, MASK)}

  # Compare the iterations per second of the various reports!
  x.compare!
end

# Warming up --------------------------------------
#           IO::Buffer   152.000  i/100ms
#               String     1.000  i/100ms
# Calculating -------------------------------------
#           IO::Buffer      1.534k (± 0.1%) i/s -      7.752k in   5.051915s
#               String     11.929  (± 0.0%) i/s -     60.000  in   5.029975s

# Comparison:
#           IO::Buffer:     1534.5 i/s
#               String:       11.9 i/s - 128.63x  slower
