(library (wsa)
  (export chunk-size
          cleanup
          close-socket
          connect
          create-server
          receive
          receive-client
          send
          server-listen)
  (import (chezscheme))
  (define (with-foreign-alloc-ptr size k)
    (let ([ptr #f])
      (dynamic-wind
        (lambda () (set! ptr (foreign-alloc size)))
        (lambda () (assert ptr) (k ptr))
        (lambda () (when ptr (foreign-free ptr))))))
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
  (define socketSend
    (foreign-procedure "socketSend" (uptr string) int))
  (define socketReceive
    (foreign-procedure "socketReceive"
      (uptr uptr int uptr)
      int))
  (define (create-server port)
    (with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketBind port ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (server-listen server back-log)
    (assert (positive? back-log))
    (assert (zero? (socketListen server back-log)))
    (void))
  (define (receive-client server)
    (with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketAccept server ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (connect server-address port)
    (with-foreign-alloc-ptr
      (foreign-sizeof 'uptr)
      (lambda (ptr)
        (assert (zero? (socketConnect server-address port ptr)))
        (foreign-ref 'uptr ptr 0))))
  (define (close-socket socket)
    (assert (zero? (socketClose socket)))
    (void))
  (define (cleanup) (assert (zero? (socketCleanup))) (void))
  (define (send socket message)
    (assert (zero? (socketSend socket message)))
    (void))
  (define (receive socket)
    (let ([len (chunk-size)] [buf-ptr #f] [size-ptr #f])
      (dynamic-wind
        (lambda ()
          (set! buf-ptr (foreign-alloc len))
          (set! size-ptr (foreign-alloc (foreign-sizeof 'int))))
        (lambda ()
          (assert buf-ptr)
          (assert size-ptr)
          (assert (zero? (socketReceive socket buf-ptr len size-ptr)))
          (let* ([size (foreign-ref 'int size-ptr 0)]
                 [raw (make-bytevector size)])
            (let loop ([i 0])
              (when (< i size)
                (bytevector-u8-set!
                  raw
                  i
                  (foreign-ref 'unsigned-8 buf-ptr i))
                (loop (add1 i))))
            raw))
        (lambda ()
          (when buf-ptr (foreign-free buf-ptr))
          (when size-ptr (foreign-free size-ptr)))))))
