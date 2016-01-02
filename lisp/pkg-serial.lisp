
(defpackage "SERIAL" (:use "CL" "FFI"))

(in-package serial)

(export '(serial-port descriptor *descriptor*
          receive-byte transmit-byte)
        *package*)


;;; read in a single byte from the serial port

(def-call-out read-in-byte
                (:name "fd_read")
                (:arguments (fd int)
                            (buf (c-ptr uchar) :out :alloca)
                            (nbytes int)
                            (partial-p boolean))
                (:return-type int)
                (:language :stdc))


;;; write out a single byte to the serial port

(def-call-out write-out-byte
                (:name "fd_write")
                (:arguments (fd int)
                            (buf (c-ptr uchar) :in :alloca)
                            (nbytes int))
                (:return-type int)
                (:language :stdc))


;;; read from serial port control structures

(def-call-out ioctl-read
                (:name "ioctl")
                (:arguments (fd int)
                            (request int)
                            (arg (c-ptr int) :out :alloca))
                (:return-type int)
                (:language :stdc))


;;; write to serial port control structures

(def-call-out ioctl-write
                (:name "ioctl")
                (:arguments (fd int)
                            (request int)
                            (arg (c-ptr int) :in :alloca))
                (:return-type int)
                (:language :stdc))


;;; byte level functions -----------------------------------------------------

;;; transmit one byte

(defmethod transmit-byte (data)
  (declare (special *descriptor*))
  (write-out-byte *descriptor* data 1))


;;; receive one byte, within the allowed time

(defmethod receive-byte (time-allowed)
  (declare (special *descriptor*))
  (let ((finish-time (+ (get-internal-real-time) time-allowed)))
    (loop until (>= (get-internal-real-time) finish-time)
          do (multiple-value-bind (result value)
               (read-in-byte *descriptor* 1 t)
               (when (eql 1 result)
                 (return value))
               (linux:usleep 1000)))))



;;;===========================================================================
;;; SERIAL PORT CLASS


;;;---------------------------------------------------------------------------

(defclass serial-port ()
  ((device :accessor device :initarg :device :initform "/dev/ttyS0")
   (baudrate :accessor baudrate :initarg :baudrate :initform linux:B9600)
   (descriptor :accessor descriptor)
   (attributes :accessor attributes)
   (half-bit-time :accessor half-bit-time :initform 15)))


;;;---------------------------------------------------------------------------
;;; get the termios attributes of a file descriptor

(defun get-attributes (descriptor)
  (multiple-value-bind (result attributes)
    (linux:tcgetattr descriptor)
    (if (zerop result) attributes (error "Could not get attributes."))))


;;;---------------------------------------------------------------------------
;;; initialise a serial port instance

(defmethod initialize-instance :after ((port serial-port) &rest initargs)
  (declare (ignore initargs))
  (let* ((descriptor (linux:open (device port)
                                 (logior linux:O_RDWR linux:O_NDELAY)
                                 (logior linux:S_IRUSR linux:S_IWUSR)))
         (attributes (get-attributes descriptor)))
    (setf (descriptor port) descriptor)
    (setf (attributes port) attributes)

    (setf (linux::termios-c_iflag attributes)
          (logior linux:IGNBRK
                  linux:IGNPAR))
    (setf (linux::termios-c_oflag attributes) 0)
    (setf (linux::termios-c_cflag attributes)
          (logior (baudrate port)
                  linux:CS8
                  linux:CSTOPB
                  linux:CREAD
                  linux:CLOCAL))
    (setf (linux::termios-c_lflag attributes) 0)
    (unless (zerop (linux:tcsetattr descriptor linux:TCSANOW attributes))
      (error "Could not set attributes."))))


;;;---------------------------------------------------------------------------
;;; print a serial port instance

(defmethod print-object ((port serial-port) stream)
  (let ((descriptor (descriptor port))
        (attributes (attributes port)))
    (prin1 (list (class-name (class-of port))
                 :descriptor descriptor
                 :cflag (linux::termios-c_cflag attributes)
                 :iflag (linux::termios-c_iflag attributes)
                 :ispeed (linux::cfgetispeed attributes)
                 :lflag (linux::termios-c_lflag attributes)
                 :line (linux::termios-c_line attributes)
                 :oflag (linux::termios-c_oflag attributes)
                 :ospeed (linux::cfgetospeed attributes))
           stream)))


;;;---------------------------------------------------------------------------


;;;==================================================

