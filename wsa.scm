(library (wsa)
  (export bytes-received
          chunk-size
          cleanup
          close-socket
          connect
          create-server
          receive
          receive-client
          receiving?
          send
          send-string
          server-listen)
  (import (chezscheme))
  (define (wsa-success n x)
    (unless (zero? x) (assertion-violationf n "code ~a" x)))
  (define (call-with-foreign-alloc-ptr n k)
    (let ([p #f])
      (dynamic-wind
        (lambda () (set! p (foreign-alloc n)))
        (lambda () (assert p) (k p))
        (lambda () (when p (foreign-free p))))))
  (define (foreign-ptr->bytevector p n)
    (let ([x (make-bytevector n)])
      (do ([i 0 (add1 i)])
          ((>= i n) x)
        (bytevector-u8-set! x i (foreign-ref 'unsigned-8 p i)))))
  (define (call-bytevector-with-foreign-ptr bv k)
    (let ([n (bytevector-length bv)])
      (call-with-foreign-alloc-ptr
        n
        (lambda (p)
          (do ([i 0 (add1 i)])
              ((>= i n) (k p n))
            (foreign-set! 'unsigned-8 p i (bytevector-u8-ref bv i)))))))
  (define chunk-size (make-parameter 1024))
  (define socketBind
    (foreign-procedure "socketBind" (int uptr) int))
  (define socketListen
    (foreign-procedure "socketListen" (uptr int) int))
  (define socketAccept
    (foreign-procedure "socketAccept" (uptr uptr) int))
  (define socketConnect
    (foreign-procedure "socketConnect" (string int uptr) int))
  (define socketClose
    (foreign-procedure "socketClose" (uptr) int))
  (define socketCleanup
    (foreign-procedure "socketCleanup" () int))
  (define socketSendString
    (foreign-procedure "socketSendString" (uptr string) int))
  (define socketSend
    (foreign-procedure "socketSend"
      (uptr uptr unsigned-int)
      int))
  (define socketBytesReady
    (foreign-procedure "socketBytesReady" (uptr uptr) int))
  (define socketIsReadReady
    (foreign-procedure "socketIsReadReady" (uptr uptr) int))
  (define socketReceive
    (foreign-procedure "socketReceive"
      (uptr uptr int uptr)
      int))
  (define (create-server port)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (wsa-success 'create-server (socketBind port ptr))
        (foreign-ref 'uptr ptr 0))))
  (define (server-listen server back-log)
    (assert (positive? back-log))
    (wsa-success 'server-listen (socketListen server back-log)))
  (define (receive-client server)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (wsa-success 'receive-client (socketAccept server ptr))
        (foreign-ref 'uptr ptr 0))))
  (define (connect server-address port)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (wsa-success
          'connect
          (socketConnect server-address port ptr))
        (foreign-ref 'uptr ptr 0))))
  (define (close-socket socket)
    (wsa-success 'close-socket (socketClose socket)))
  (define (cleanup) (wsa-success 'cleanup (socketCleanup)))
  (define (send-string socket message)
    (wsa-success
      'send-string
      (socketSendString socket message)))
  (define (send socket bytevector)
    (call-bytevector-with-foreign-ptr
      bytevector
      (lambda (ptr len)
        (wsa-success 'send (socketSend socket ptr len)))))
  (define (receive socket)
    (let ([n (chunk-size)])
      (call-with-foreign-alloc-ptr
        n
        (lambda (p)
          (call-with-foreign-alloc-ptr
            (foreign-sizeof 'int)
            (lambda (np)
              (wsa-success 'receive (socketReceive socket p n np))
              (foreign-ptr->bytevector p (foreign-ref 'int np 0))))))))
  (define (bytes-received socket)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'unsigned-32)
      (lambda (p)
        (foreign-set! 'unsigned-32 p 0 0)
        (wsa-success 'bytes-received (socketBytesReady socket p))
        (foreign-ref 'unsigned-32 p 0))))
  (define (receiving? socket)
    (call-with-foreign-alloc-ptr
      1
      (lambda (p)
        (foreign-set! 'unsigned-8 p 0 0)
        (wsa-success 'receiving? (socketIsReadReady socket p))
        (positive? (foreign-ref 'unsigned-8 p 0))))))
