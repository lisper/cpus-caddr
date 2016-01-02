
(setq device "/dev/ttyS5")
(setq baudrate linux:B9600)

(defun get-attributes (descriptor)
  (multiple-value-bind (result attributes)
    (linux:tcgetattr descriptor)
    (if (zerop result) attributes (error "Could not get attributes."))))


(defun xxx ()
  (let* ((descriptor (linux:open "/dev/ttyS0" ;;(device port)
;			       (logior linux:O_RDWR linux:O_NDELAY)
			       linux:O_RDWR 
			       (logior linux:S_IRUSR linux:S_IWUSR)))
       (attributes (get-attributes descriptor)))
;  (setf (descriptor port) descriptor)
;  (setf (attributes port) attributes)

;  (setf (linux::termios-c_iflag attributes)
;	(logior linux:IGNBRK
;		linux:IGNPAR))
;  (setf (linux::termios-c_oflag attributes) 0)
;  (setf (linux::termios-c_cflag attributes)
;	(logior baudrate
;		linux:CS8
;		linux:CSTOPB
;		linux:CREAD
;		linux:CLOCAL))
;  (setf (linux::termios-c_lflag attributes) 0)
(format t "descriptor ~d~%" descriptor)
(format t "attributes ~x~%" attributes)
  (linux:tcsetattr descriptor linux:TCSANOW (linux:tcgetattr descriptor))
;  (linux:tcsetattr descriptor linux:TCSANOW attributes)
;  (unless (zerop (linux:tcsetattr descriptor linux:TCSANOW attributes))
;    (error "Could not set attributes."))
))


;-----

;stty -F /dev/ttyS0 9600 raw -parenb -parodd cs8 -hupcl -cstopb clocal

;(with-open-file (stream "/dev/ttyS0"
;			:direction :io
;			:if-exists :overwrite
;;			:external-format :ascii
;			)
;
;(defun next-cadr-char ()
;  (read-char stream))
;
;(defun next-cadr-byte ()
;  (char-code (next-cadr-char)))
;

; debug
(let ((*cp* 0))
  (defun next-cadr-byte ()
    (setq *cp* (if (< *cp* 4) (+ 1 *cp*) 1))
    (case *cp*
      (1 #x31)
      (2 #x42)
      (3 #x53)
      (4 #x64)))
  (defun put-cadr-byte (cmd)
    ))

(defun cadr-get-resp ()
  (let* ((c1 (next-cadr-byte))
	 (c2 (next-cadr-byte))
	 (c3 (next-cadr-byte))
	 (c4 (next-cadr-byte)))

	 (if (and (= (logand c1 #xf0) #x30)
		  (= (logand c2 #xf0) #x40)
		  (= (logand c3 #xf0) #x50)
		  (= (logand c4 #xf0) #x60))
	     (logior (ash (logand c1 #x0f) 12.)
		     (ash (logand c2 #x0f) 8.)
		     (ash (logand c3 #x0f) 4.)
		     (ash (logand c4 #x0f) 0.))
	     (progn
	       (format t "bad response ~2x ~2x ~2x ~2x ~%" c1 c2 c3 c4)
	       0))))

(defun cadr-send-cmd (cmd)
  (put-cadr-byte cmd))

;(format t "test ~x~%" (get-cadr-resp))

(defun spy-read (regn)
  (let ((cmd (logior #x80 regn)))
    (format t "dbg-read reg ~o~%" regn)
    (cadr-send-cmd cmd)
    (let ((resp (cadr-get-resp)))
      (format t "dbg-read reg ~o -> ~o~%" regn resp)
      resp)))

(defun spy-write (regn val)
  (let ((c1 (logior #x30 (logand #x0f (ash val -12.))))
	(c2 (logior #x40 (logand #x0f (ash val -8.))))
	(c3 (logior #x50 (logand #x0f (ash val -4.))))
	(c4 (logior #x60 (logand #x0f (ash val -0.))))
	(cmd (logior #x90 regn)))
    (progn
      (cadr-send-cmd c1)
      (cadr-send-cmd c2)
      (cadr-send-cmd c3)
      (cadr-send-cmd c4)
      (cadr-send-cmd cmd)
      (format t "dbg-write reg ~o <- ~o~%" regn val))))

