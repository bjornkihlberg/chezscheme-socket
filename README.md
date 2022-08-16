# chezscheme-socket

A simple TCP library for Chez Scheme

---

**Hint:** If you're using Windows you can use the excellent tool [Hercules](https://www.hw-group.com/software/hercules-setup-utility) for debugging your socket applications.

## Quickstart

### Winsock2 Server example

```scheme
(import (winsock2))

(wsa-startup 2 2)

; Create a server.
(define server (socket AF_INET SOCK_STREAM 0))
(bind s AF_INET INADDR_ANY (htons 8000))

; Start listening for incoming client connections.
(listen server 3) ; Allow up to 3 pending clients waiting for connection

; Check if there are any pending clients
(positive? (wsa-poll server POLLRDNORM 1 0)) ; returns #t means accept will return immediately

; Accept an incoming client connection.
; Note: accept blocks the running thread until a client has been received!
(define client (accept server)) ; returns a socket

; Close a socket when you're done with it.
(close-socket server)

; Send data on a socket with send or send-string.
; Note: send takes a bytevector while send-string takes a string.
(send client (string->utf8 "Hello, client!\n") 0)

; Check if there is incoming information.
(positive? (wsa-poll client POLLRDNORM 1 0)) ; returns #t means recv will return immediately

; Receive data on a socket.
; Note:
;  This procedure blocks the running thread until a message has been received.
;  receive consumes data on a socket up to a number of bytes as specified by the
;  parameter chunk-size. Default is 1024 bytes. If the message is incomplete,
;  invoke receive again to get the rest of the message or parameterize chunk-size
;  with a bigger number.
(utf8->string (recv client 0))

(close-socket client)

; Unload the Windows Socket API with when you're done with it.
(cleanup)
```

### Winsock2 Client example

```scheme
(import (winsock2))

(wsa-startup 2 2)

; Connect to a server.
(define server (socket AF_INET SOCK_STREAM 0))
(connect s AF_INET (inet_addr "127.0.0.1") (htons 8000))

; Send data on a socket with send or send-string.
; Note: send takes a bytevector while send-string takes a string.
(send server (string->utf8 "Hello, server!\n") 0)

; Check if there is incoming information.
(positive? (wsa-poll server POLLRDNORM 1 0)) ; returns #t means recv will return immediately

; Receive data on a socket.
; Note:
;  This procedure blocks the running thread until a message has been received.
;  receive consumes data on a socket up to a number of bytes as specified by the
;  parameter chunk-size. Default is 1024 bytes. If the message is incomplete,
;  invoke receive again to get the rest of the message or parameterize chunk-size
;  with a bigger number.
(utf8->string (recv server 0))

; Close a socket when you're done with it.
(close-socket server)

; Unload the Windows Socket API with when you're done with it.
(cleanup)
```

## ⚠ Thread safety

-  `recv` **must not** be invoked at the same for the same socket time on different threads. The same goes for `send`.
- `recv` and `send` can however safely be invoked at the same time for the same socket on different threads without issues.

## Notes

Right now this library only wraps some basic functionality in the Windows Socket API (winsock2). I won't go far beyond this except a few things:

- ~~Don't use C++, wrap **Ws2_32.dll** directly in **wsa.scm**~~ Done
- Implement a Linux version
