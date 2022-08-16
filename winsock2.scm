(load-shared-object "Ws2_32.dll")

(and (assert (string=? (getenv "os") "Windows_NT"))
     (assert (foreign-entry? "WSAStartup"))
     (assert (foreign-entry? "WSAGetLastError"))
     (assert (foreign-entry? "htons"))
     (assert (foreign-entry? "bind"))
     (assert (foreign-entry? "listen"))
     (assert (foreign-entry? "accept"))
     (assert (foreign-entry? "inet_addr"))
     (assert (foreign-entry? "connect"))
     (assert (foreign-entry? "send"))
     (assert (foreign-entry? "WSAPoll"))
     (assert (foreign-entry? "recv"))
     (assert (foreign-entry? "closesocket"))
     (assert (foreign-entry? "WSACleanup"))
     (assert (foreign-entry? "socket")))

(library (winsock2)
  (export AF_APPLETALK
          AF_BTH
          AF_INET
          AF_INET6
          AF_IPX
          AF_IRDA
          AF_NETBIOS
          AF_UNSPEC
          INADDR_ANY
          INVALID_SOCKET
          POLLRDBAND
          POLLRDNORM
          POLLWRNORM
          SOCKET_ERROR
          SOCK_DGRAM
          SOCK_RAW
          SOCK_RDM
          SOCK_SEQPACKET
          SOCK_STREAM
          accept
          bind
          chunk-size
          close-socket
          connect
          htons
          inet_addr
          listen
          recv
          send
          socket
          wsa-cleanup
          wsa-poll
          wsa-startup)
  (import (chezscheme) (prefix (ffi) ffi.))
  (meta define _WIN64 (= (ftype-sizeof uptr) 8))
  (define INVALID_SOCKET (sub1 (expt 2 (* 8 (ftype-sizeof SOCKET)))))
  (define AF_UNSPEC 0)
  (define AF_INET 2)
  (define AF_IPX 6)
  (define AF_APPLETALK 16)
  (define AF_NETBIOS 17)
  (define AF_INET6 23)
  (define AF_IRDA 26)
  (define AF_BTH 32)
  (define SOCK_STREAM 1)
  (define SOCK_DGRAM 2)
  (define SOCK_RAW 3)
  (define SOCK_RDM 4)
  (define SOCK_SEQPACKET 5)
  (define SOCKET_ERROR -1)
  (define INADDR_ANY 0)
  (define INADDR_NONE 4294967295)
  (define POLLRDBAND 512)
  (define POLLRDNORM 256)
  (define POLLWRNORM 16)
  (define-ftype VERSION (struct [minor unsigned-8] [major unsigned-8]))
  (define-ftype SOCKET uptr)
  (meta-cond
    [_WIN64
     (define-ftype WSADATA
       (struct
         [wVersion VERSION]
         [wHighVersion VERSION]
         [iMaxSockets unsigned-short]
         [iMaxUdpDg unsigned-short]
         [lpVendorInfo (* char)]
         [szDescription (array 257 char)]
         [szSystemStatus (array 129 char)]))]
    [else
     (define-ftype WSADATA
       (struct
         [wVersion VERSION]
         [wHighVersion VERSION]
         [szDescription (array 257 char)]
         [szSystemStatus (array 129 char)]
         [iMaxSockets unsigned-short]
         [iMaxUdpDg unsigned-short]
         [lpVendorInfo (* char)]))])
  (define-ftype sockaddr_in
    (struct
      [sin_family short]
      [sin_port unsigned-short]
      [sin_addr unsigned-int]
      [sin_zero (array 8 char)]))
  (define-ftype pollfd (struct [fd SOCKET] [events short] [revents short]))
  (define chunk-size (make-parameter 1024))
  (define (make-word low high)
    (bitwise-ior low (bitwise-arithmetic-shift-left high 8)))
  (define WSAGetLastError (foreign-procedure "WSAGetLastError" () int))
  (define (raise-wsa-error who)
    (assertion-violationf who "wsa error code ~a" (WSAGetLastError)))
  (define WSAStartup
    (foreign-procedure "WSAStartup" (unsigned-16 (* WSADATA)) int))
  (define (wsa-startup major-version minor-version)
    (define (k ptr)
      (let ([wsa-data-ptr (make-ftype-pointer WSADATA ptr)]
            [version (make-word minor-version major-version)])
        (unless (zero? (WSAStartup version wsa-data-ptr))
          (raise-wsa-error 'wsa-startup))
        (ftype-pointer->sexpr wsa-data-ptr)))
    (ffi.call-with-ptr (ftype-sizeof WSADATA) k))
  (define _socket (foreign-procedure "socket" (int int int) SOCKET))
  (define (socket af type protocol)
    (let ([result (_socket af type protocol)])
      (if (= result INVALID_SOCKET) (raise-wsa-error 'socket) result)))
  (define htons (foreign-procedure "htons" (unsigned-short) unsigned-short))
  (define _bind (foreign-procedure "bind" (SOCKET (* sockaddr_in) int) int))
  (define (bind s sin_family sin_addr sin_port)
    (define len (ftype-sizeof sockaddr_in))
    (define (k ptr)
      (let ([ptr (make-ftype-pointer sockaddr_in ptr)])
        (ftype-set! sockaddr_in (sin_family) ptr sin_family)
        (ftype-set! sockaddr_in (sin_addr) ptr sin_addr)
        (ftype-set! sockaddr_in (sin_port) ptr sin_port)
        (when (= (_bind s ptr len) SOCKET_ERROR) (raise-wsa-error 'bind))))
    (ffi.call-with-ptr len k))
  (define _connect (foreign-procedure "connect" (SOCKET (* sockaddr_in) int) int))
  (define (connect s sin_family sin_addr sin_port)
    (define len (ftype-sizeof sockaddr_in))
    (define (k ptr)
      (let ([ptr (make-ftype-pointer sockaddr_in ptr)])
        (ftype-set! sockaddr_in (sin_family) ptr sin_family)
        (ftype-set! sockaddr_in (sin_addr) ptr sin_addr)
        (ftype-set! sockaddr_in (sin_port) ptr sin_port)
        (when (negative? (_connect s ptr len)) (raise-wsa-error 'connect))))
    (ffi.call-with-ptr len k))
  (define _listen (foreign-procedure "listen" (SOCKET int) int))
  (define (listen s back-log)
    (assert (positive? back-log))
    (when (= (_listen s back-log) SOCKET_ERROR) (raise-wsa-error 'listen)))
  (define WSAPoll
    (foreign-procedure "WSAPoll" ((* pollfd) unsigned-long int) int))
  (define (wsa-poll s events fds timeout)
    (define (k ptr)
      (let ([ptr (make-ftype-pointer pollfd ptr)])
        (ftype-set! pollfd (fd) ptr s)
        (ftype-set! pollfd (events) ptr events)
        (ftype-set! pollfd (revents) ptr 0)
        (let ([result (WSAPoll ptr fds timeout)])
          (if (= result SOCKET_ERROR) (raise-wsa-error 'wsa-poll) result))))
    (ffi.call-with-ptr (ftype-sizeof pollfd) k))
  (define _accept
    (foreign-procedure "accept" (SOCKET (* sockaddr_in) (* int)) SOCKET))
  (define (accept s)
    (define (k1 ptr1)
      (define (k2 ptr2)
        (let ([ptr1 (make-ftype-pointer sockaddr_in ptr1)]
              [ptr2 (make-ftype-pointer int ptr2)])
          (ftype-set! int () ptr2 (ftype-sizeof sockaddr_in))
          (let ([result (_accept s ptr1 ptr2)])
            (if (= result INVALID_SOCKET) (raise-wsa-error 'accept) result))))
      (ffi.call-with-ptr (ftype-sizeof int) k2))
    (ffi.call-with-ptr (ftype-sizeof sockaddr_in) k1))
  (define _close-socket (foreign-procedure "closesocket" (SOCKET) int))
  (define (close-socket s)
    (when (= (_close-socket s) SOCKET_ERROR) (raise-wsa-error 'close-socket)))
  (define _send (foreign-procedure "send" (SOCKET uptr int int) int))
  (define (send s data flags)
    (define (k ptr len)
      (when (negative? (_send s ptr len flags)) (raise-wsa-error 'send)))
    (ffi.call-bytevector-with-ptr data k))
  (define _recv (foreign-procedure "recv" (SOCKET uptr int int) int))
  (define (recv s flags)
    (define len (chunk-size))
    (define (k ptr)
      (let ([n-bytes-received (_recv s ptr len flags)])
        (if (= n-bytes-received SOCKET_ERROR)
            (raise-wsa-error 'recv)
            (let ([result (make-bytevector n-bytes-received)])
              (do ([i 0 (add1 i)])
                  ((>= i n-bytes-received) result)
                (bytevector-u8-set! result i (foreign-ref 'unsigned-8 ptr i)))))))
    (ffi.call-with-ptr len k))
  (define WSACleanup (foreign-procedure "WSACleanup" () int))
  (define (wsa-cleanup)
    (when (= (WSACleanup) SOCKET_ERROR) (raise-wsa-error 'wsa-cleanup)))
  (define _inet_addr (foreign-procedure "inet_addr" (string) unsigned-64))
  (define (inet_addr address)
    (let ([result (_inet_addr address)])
      (cond
        [(= result INADDR_ANY)
         (assertion-violationf 'inet_addr "returned error value INADDR_ANY")]
        [(= result INADDR_NONE)
         (assertion-violationf 'inet_addr "returned error value INADDR_NONE")]
        [else result]))))
