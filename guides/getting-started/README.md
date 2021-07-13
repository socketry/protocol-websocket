# Getting Started

This guide explains how to use `protocol-websocket` for implementing a websocket client and server.

## Installation

Add the gem to your project:

~~~ bash
$ bundle add protocol-websocket
~~~

## Core Concepts

`protocol-websocket` has several core concepts:

- A {ruby Protocol::WebSocket::Frame} is the base class which is used to represent protocol-specific structured frames.
- A {ruby Protocol::WebSocket::Framer} wraps an underlying {ruby Async::IO::Stream} for reading and writing binary data into structured frames.
- A {ruby Protocol::WebSocket::Connection} wraps a framer and implements for implementing connection specific interactions like reading and writing text.

## Bi-directional Communication

We can create a small bi-directional WebSocket client server:

~~~ ruby
require 'protocol/websocket'
require 'protocol/websocket/connection'
require 'socket'

sockets = Socket.pair(Socket::PF_UNIX, Socket::SOCK_STREAM)

client = Protocol::WebSocket::Connection.new(Protocol::WebSocket::Framer.new(sockets.first))
server = Protocol::WebSocket::Connection.new(Protocol::WebSocket::Framer.new(sockets.last))

client.send_text("Hello World")
pp server.read
~~~
