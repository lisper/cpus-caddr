(setq x (format nil "hello ~d" 10))
(format t "result: ~s~%" x)
(exit)

(setq *READ-BASE* 8)

(setq x (ash #o31 1))
(setq y (ash #o37 1))

(setq arg 1)

(format t "blah ~d~%" (max arg 1))

(setq n 0)
(DO ((N 0 (+ 1 N))) ((= N 4))
  (format t "hi ~d~%" N))


(setq arg 3)

(progn
  (DO ((N (MAX ARG 1) (1- N))) ((= N 0))
      (format t "hi ~d~%" N)))

