# Extensions

WebSockets have a mechanism for implementing extensions. The only published extension is for per-message compression. It operates on complete messages rather than individual frames.

## Setup

Clients need to define a set of extensions they want to support. The server then receives this via the `Sec-WebSocket-Extensions` header which includes a list of:

	Name, Options

The server processes this and returns a subset of accepted `(Name, Options)`. It also instantiates the extensions and applies them to the server connection object.

The client receives a list of accepted `(Name, Options)` and instantiates the extensions and applies them to the client connection object.
