(defun get-posix-baud (baud)
  (when (stringp baud)
    (setf baud (parse-integer baud)))
  (case baud
    (110 sb-posix:b110)
    (300 sb-posix:b300)
    (1200 sb-posix:b1200)
    (2400 sb-posix:b2400)
    (4800 sb-posix:b4800)
    (9600 sb-posix:b9600)
    (19200 sb-posix:b19200)
    (38400 sb-posix:b38400)
    (57600 sb-posix:b57600)
    (115200 sb-posix:b115200)
    (230400 sb-posix:b230400)
    (otherwise sb-posix:b19200)))

(defun open-serial (tty &optional (baud 9600))
  (handler-case
      (let* ((fd (sb-posix:open
		  tty
		  (boole boole-ior
			 (boole boole-ior sb-posix:O-RDWR sb-posix:O-NOCTTY)
			 sb-posix:O-NDELAY)))
	     (options (sb-posix:tcgetattr fd))
	     (serial-stream nil)
	     (posix-baud (get-posix-baud baud)))
	(sb-posix:cfsetispeed posix-baud options)
	(sb-posix:cfsetospeed posix-baud options)
	(setf (sb-posix:termios-cflag options)
	      (boole boole-ior sb-posix:CLOCAL sb-posix:CREAD))
	(setf (sb-posix:termios-cflag options)
	      (boole boole-and
		     (sb-posix:termios-cflag options) (boole boole-c1 sb-posix:PARENB 0)))
	(setf (sb-posix:termios-cflag options)
	      (boole boole-and
		     (sb-posix:termios-cflag options) (boole boole-c1 sb-posix:CSTOPB 0)))
	(setf (sb-posix:termios-cflag options)
	      (boole boole-and
		     (sb-posix:termios-cflag options) (boole boole-c1 sb-posix:CSIZE 0)))
	(setf (sb-posix:termios-cflag options)
	      (boole boole-ior (sb-posix:termios-cflag options) sb-posix:CS8))
	(sb-posix:tcsetattr fd sb-posix:TCSANOW options)
	(setf serial-stream
	      (sb-sys:make-fd-stream fd
				     :input t :output t
				     :element-type unsigned-byte
				     :buffering :full))
	(values serial-stream fd))
    (error (condition)
      (format t Problem opening serial port ~A: ~A tty condition))))

(defun close-serial (fd)
  (sb-posix:fcntl fd sb-posix:F-SETFL 0)
  (sb-posix:close fd))

(let ((bcode nil))
  (defun data-received-handler (stream)
    (logger :info DATA-RECEIVED-HANDLER called on ~A stream)
    (handler-case
	(let ((c nil))
	  (loop
	     (setf c (read-byte stream))
	     (logger :info SERIAL GOT: ~A / ~A c (code-char c))
	     (cond ((eql c 13)
		    (logger :info ENQUEUEING ~A (reverse bcode))
		    (sb-queue:enqueue (format nil ~{~a~} (reverse bcode))
				      *barcode-reader-queue*)
		    (setf bcode nil))
		   ((eql c 10) (return))
		   ((eql c 2) (setf bcode nil))
		   (t (push (code-char c) bcode)))))
      (end-of-file (condition)
	(declare (ignore condition)))
      (error (condition)
	(logger :err DATA-RECEIVED-HANDLER GOT ERROR: ~A condition)))))

(defun create-input-handler (stream fd)
  (handler-case
      (sb-sys:add-fd-handler
       fd :input
       #(lambda (fd)
	 (declare (ignore fd))
	 (data-received-handler stream)))
    (error (condition)
      (logger :err Problem initiating fd handler: ~A condition)
      (close-serial fd))))

(defun activate-scanner (tty)
  (setf *barcode-reader-thread-off* nil)
  (setf *barcode-reader-queue* (sb-queue:make-queue))
  (setf *barcode-reader-thread*
	(sb-thread:make-thread
	 #(lambda ()
	   (multiple-value-bind (stream fd) (open-serial tty)
	     (create-input-handler stream fd)
	     (loop
		(if *barcode-reader-thread-off*
		    (ignore-errors
		      (close-serial fd)
		      (return nil))
		    (handler-case
			(sb-sys:serve-all-events 0.5)
		      (error (condition)
			(ignore-errors (close-serial fd))
			(logger :err Unahndled error in barcode reader thread: ~A condition)
			(return nil)))))))
	 :name scanner-thread)))

(defun deactivate-scanner ()
  (setf *barcode-reader-thread-off* t)
  (sb-thread:join-thread *barcode-reader-thread*)
  (setf *barcode-reader-thread* nil))

