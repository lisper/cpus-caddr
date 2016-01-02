(setq *READ-BASE* 8)

(defmacro comment (&rest body)
  "Comment out one or more s-expressions.")

(defmacro samefunction (new old)
  `(progn  (setf  (symbol-function ',new)
		  (symbol-function ',old))
	   ',new))

(samefunction defconst defconstant)

(defun array-to-bignum (bignum-array fixnum sign)
  (+ 0 0))

(defun byte-position-old (bytespec)
  (logand (ash bytespec -6.) #o0077))

(defun byte-size-old (bytespec)
  (logand bytespec #o0077))

; convert old style lispm byte spec to new cl byte spec
(defun cvt-old-byte-spec (old-bytespec)
  (byte (byte-position-old old-bytespec)
	(byte-size-old old-bytespec)))

;(print (lispm-byte-spec #o0401))
;(exit)

(defun ldb-old (bytespec integer)
  (let ((mask (- (ash 1 (byte-size-old bytespec)) 1)))
    (logand (ash integer (- (byte-position-old bytespec))) mask)))

(samefunction logldb-old ldb-old)

(defun dpb-old (newbyte bytespec integer)
  (let ((mask (ash 
	       (- (ash 1 (byte-size-old bytespec)) 1) 
	       (byte-position-old bytespec))))
    (logior 
     (logand integer (lognot mask))
     (logand (ash newbyte (byte-position-old bytespec)) mask))))

(samefunction logdpb-old dpb-old)

;(defconstant +fixnum-bits+ 24.)
(defconstant +fixnum-bits+ 32.)

(defun lsh (integer count)
  (assert (integerp integer))
  (if (>= count 0)
      (cl:ash integer count)
      (let ((count (- 0 count)))
	(cl:dpb (cl:ldb (byte (- +fixnum-bits+ count) count) integer)
		(byte (- +fixnum-bits+ count) 0) 
		0))))

;(print (lsh 1 6))
;(print (lsh 1 -6))
;(exit)

(defun bit-test (bitmask bitvector)
  (ZEROP (LOGAND bitmask bitvector)))

(DEFMACRO DEFPROP (PROP NAME &rest body)
   `(SETF (GET ',NAME ',PROP) ',body))

(DEFMACRO PUTPROP (NAME VALUE PROP)
   `(SETF (GET ,PROP ,NAME) ,VALUE))

;(DEFUN SPY-READ (REGN)
;  (format t "dbg-read reg ~o~%" regn)
;  0)

;(DEFUN SPY-WRITE (REGN VAL)
;  (format t "dbg-write reg ~o <- ~o~%" regn val))

(load "cadreg.lisp")
(load "lcadmc.lisp")
(load "lcadrd.lisp")
(load "diags.lisp")
(load "serial.lisp")

(defun dbg-write (addr val)
  (format t "dbg-write ~o <- ~o~%" addr val))

(format t "stop:~%")
(cc-stop-mach)
(format t "step:~%")
(cc-step-mach 1)
(format t "step:~%")
(cc-step-mach 1)
(format t "start:~%")
(cc-start-mach)
(format t "done~%")

(defun dbg-reset ()
  t)
(defun dbg-reset-status ()
  t)
(defun dbg-write-unibus-map (a1 a2)
  t)

(defun send (send-to send-how what)
  (format t "~s~%" what))

(setq TERMINAL-IO 0)

(defun sub1 (n) (- n 1))

(setq dbg-access-path nil)


(format t "read:~%")
;(cc-read-vma)
(cc-read-md)
;(cc-read-pc)
;(cc-read-a-bus)
;(cc-read-m-bus)

;(format t "cc-test-machine:~%")
;(cc-test-machine)
