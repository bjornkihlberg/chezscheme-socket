(library (wsa)
  (export chunk-size
          cleanup
          close-socket
          connect
          create-server
          receive
          receive-client
          receive-string
          send
          send-string
          server-listen)
  (import (chezscheme))
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
  (define socketReceive
    (foreign-procedure "socketReceive"
      (uptr uptr int uptr)
      int))
  (define (create-server port)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketBind port ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (server-listen server back-log)
    (assert (positive? back-log))
    (assert (zero? (socketListen server back-log)))
    (void))
  (define (receive-client server)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketAccept server ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (connect server-address port)
    (call-with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketConnect server-address port ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (close-socket socket)
    (assert (zero? (socketClose socket)))
    (void))
  (define (cleanup) (assert (zero? (socketCleanup))) (void))
  (define (send-string socket message)
    (assert (zero? (socketSendString socket message)))
    (void))
  (define (send socket bytevector)
    (call-bytevector-with-foreign-ptr
      bytevector
      (lambda (ptr len)
        (assert (zero? (socketSend socket ptr len)))
        (void))))
  (define (receive socket)
    (let ([n (chunk-size)])
      (call-with-foreign-alloc-ptr
        n
        (lambda (p)
          (assert p)
          (call-with-foreign-alloc-ptr
            (foreign-sizeof 'int)
            (lambda (np)
              (assert np)
              (assert (zero? (socketReceive socket p n np)))
              (foreign-ptr->bytevector p (foreign-ref 'int np 0))))))))
  (define (receive-string socket)
    (utf8->string (receive socket))))
