#!/usr/bin/env -S falcon serve --bind http://127.0.0.1:9001 --count 1 -c

require "async/websocket/adapters/rack"

# TODO: This should probably be part of the library long-term
class RawConnection < Async::WebSocket::Connection
  def parse(buffer)
    buffer
  end

  def dump(buffer)
    buffer
  end
end

app = lambda do |env|
  Async::WebSocket::Adapters::Rack.open(env, handler: RawConnection) do |c|
    while message = c.read
      c.write(message)
    end
  end or [404, {}, []]
end

run app
