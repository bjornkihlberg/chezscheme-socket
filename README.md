# chezscheme-socket

A simple TCP library for Chez Scheme

---

Requires **wsa.dll** Can either be found in **wsa-win-mingw-x64.zip** under [latest release](https://github.com/bjornkihlberg/chezscheme-socket/releases/tag/latest) or compiled directly from **wsa.cpp**. The `wsa` library is specifically for use with Windows. I haven't yet implemented a socket library for Linux.

**Hint:** If you're using Windows you can use the excellent tool [Hercules](https://www.hw-group.com/software/hercules-setup-utility) for debugging your socket applications.

## Quickstart

Begin by loading the shared object and then import the `wsa` library.

```scheme
(load-shared-object "wsa.dll")
```

> 💡 I decided to try out not loading the .dll-file from within **wsa.scm** to allow dependent projects to decide how to organize their .dll-files.

### WSA Server example

```scheme
(import (wsa))

(define server (create-server 8000)) ; Create a server

; Start listening for incoming client connections.
(server-listen server 3) ; Allow up to 3 pending clients waiting for connection

; Accept an incoming client connection.
; Note: receive-client blocks the running thread until a client has been received!
(define client (receive-client server)) ; Returns a socket

; Send data on a socket with send or send-string.
; Note: send takes a bytevector while send-string takes a string.
(send-string client "Hello, client!\n")

; Receive data on a socket with receive or receive-string.
; Note:
;  receive returns a bytevector while receive-string returns a string.
;  These procedures blocks the running thread until a message has been received.
;  These procedures consumes data on a socket up to a number of bytes as
;  specified by the parameter chunk-size. Default is 1024 bytes. If the message is
;  incomplete, invoke receive again to get the rest of the message or parameterize
;  chunk-size with a bigger number.
(receive-string client)

; Close a socket when you're done with it.
(close-socket server)

; Unload the Windows Socket API with when you're done with it.
(cleanup server)
```

### WSA Client example

```scheme
(define server (wsa.connect "127.0.0.1" 8000)) ; Connect to a server

; Send data on a socket with send or send-string.
; Note: send takes a bytevector while send-string takes a string.
(send-string server "Hello, server!\n")

; Receive data on a socket with receive or receive-string.
; Note:
;  receive returns a bytevector while receive-string returns a string.
;  These procedures blocks the running thread until a message has been received.
;  These procedures consumes data on a socket up to a number of bytes as
;  specified by the parameter chunk-size. Default is 1024 bytes. If the message is
;  incomplete, invoke receive again to get the rest of the message or parameterize
;  chunk-size with a bigger number.
(receive-string server)

; Close a socket when you're done with it.
(close-socket server)

; Unload the Windows Socket API with when you're done with it.
(cleanup server)
```

## Thread safety

- ⚠ The receive procedures **must not** be invoked at the same for the same socket time on different threads.

  The same goes for the send procedures.

- A receive procedure and a send procedure can however safely be invoked at the same time for the same socket on different threads without issues.

## Notes

Right now this library only wraps the Windows Socket API (winsock). Some future work includes:

- Implement non-blocking receive procedures.
- Maybe use custom binary ports.
- Don't use C++, wrap **Ws2_32.dll** directly in **wsa.scm**.
- Implement a Linux version.
