;;;; This file is for testing external-format functionality for
;;;; ISO-8859-2, using test machinery which does not have side
;;;; effects.  Note that the tests here reach into unexported
;;;; functionality, and should not be used as a guide for users.

;;;; This software is part of the SBCL system. See the README file for
;;;; more information.
;;;;
;;;; While most of SBCL is derived from the CMU CL system, the test
;;;; files (like this one) were written from scratch after the fork
;;;; from CMU CL.
;;;;
;;;; This software is in the public domain and is provided with
;;;; absolutely no warranty. See the COPYING and CREDITS files for
;;;; more information.

#-sb-unicode (invoke-restart 'run-tests::skip-file)

(defvar *test-path* (scratch-file-name))

(macrolet ((input-test (inxf expected &environment env)
             `(progn
                (with-test (:name (,(macroexpand 'name env) :file ,inxf))
                  (with-open-file (s *test-path* :external-format ',inxf)
                    (let* ((string (make-string 20))
                           (count (read-sequence string s)))
                      (assert (equal (map 'list 'identity (subseq string 0 count)) ,expected)))))
                (with-test (:name (,(macroexpand 'name env) :octets ,inxf))
                  (let ((octets (coerce bytes '(simple-array (unsigned-byte 8) 1))))
                    (assert (equal (sb-ext:octets-to-string octets :external-format ',inxf)
                                   (coerce ,expected 'string)))))))
           (with-input-bytes ((id bytes) &body body)
             `(let ((bytes ,bytes))
                (with-open-file (s *test-path* :element-type '(unsigned-byte 8)
                                   :direction :output :if-exists :supersede)
                  (dolist (byte bytes)
                    (write-byte byte s)))
                (symbol-macrolet ((name ,id))
                  (macrolet ((test (inxf expected)
                               `(input-test ,inxf ,expected)))
                    ,@body))))
           (output-test (chars outxf expected &environment env)
             `(progn
                (with-open-file (s *test-path* :element-type 'character
                                   :external-format ',outxf
                                   :direction :output :if-exists :supersede)
                  (write-sequence ,chars s))
                (with-test (:name (,(macroexpand 'name env) :file ,outxf))
                  (with-open-file (s *test-path* :element-type '(unsigned-byte 8))
                    (let* ((vector (make-array 20 :element-type '(unsigned-byte 8)))
                           (count (read-sequence vector s)))
                      (assert (equal (map 'list 'identity (subseq vector 0 count)) ,expected)))))
                (with-test (:name (,(macroexpand 'name env) :octets ,outxf))
                  (let* ((string (coerce chars 'string))
                         (octets (sb-ext:string-to-octets string :external-format ',outxf)))
                    (assert (typep octets '(simple-array (unsigned-byte 8) 1)))
                    (assert (equal (coerce octets 'list) ,expected))))))
           (with-output-characters ((id chars) &body body)
             `(let ((chars ,chars))
                (symbol-macrolet ((name ,id))
                  (macrolet ((test (outxf expected)
                               `(output-test chars ,outxf ,expected)))
                    ,@body)))))
  (with-input-bytes ((:input :lf) '(#xb7 #x0a #x37))
    (test :iso-8859-2 '(#\CARON #\Newline #\7))
    (test (:iso-8859-2 :newline :lf) '(#\CARON #\Newline #\7))
    (test (:iso-8859-2 :newline :cr) '(#\CARON #\Newline #\7))
    (test (:iso-8859-2 :newline :crlf) '(#\CARON #\Newline #\7)))
  (with-output-characters ((:output :lf) '(#\CARON #\Linefeed #\7))
    (test :iso-8859-2 '(#xb7 #x0a #x37))
    (test (:iso-8859-2 :newline :lf) '(#xb7 #x0a #x37))
    (test (:iso-8859-2 :newline :cr) '(#xb7 #x0d #x37))
    (test (:iso-8859-2 :newline :crlf) '(#xb7 #x0d #x0a #x37)))
  (with-input-bytes ((:input :cr) '(#xb7 #x0d #x37))
    (test :iso-8859-2 '(#\CARON #\Return #\7))
    (test (:iso-8859-2 :newline :lf) '(#\CARON #\Return #\7))
    (test (:iso-8859-2 :newline :cr) '(#\CARON #\Newline #\7))
    (test (:iso-8859-2 :newline :crlf) '(#\CARON #\Return #\7)))
  (with-output-characters ((:output :cr) '(#\CARON #\Return #\7))
    (test :iso-8859-2 '(#xb7 #x0d #x37))
    (test (:iso-8859-2 :newline :lf) '(#xb7 #x0d #x37))
    (test (:iso-8859-2 :newline :cr) '(#xb7 #x0d #x37))
    (test (:iso-8859-2 :newline :crlf) '(#xb7 #x0d #x37)))
  (with-input-bytes ((:input :crlf) '(#xb7 #x0d #x0a #x37))
    (test :iso-8859-2 '(#\CARON #\Return #\Newline #\7))
    (test (:iso-8859-2 :newline :lf) '(#\CARON #\Return #\Newline #\7))
    (test (:iso-8859-2 :newline :cr) '(#\CARON #\Newline #\Newline #\7))
    (test (:iso-8859-2 :newline :crlf) '(#\CARON #\Newline #\7)))
  (with-output-characters ((:output :crlf) '(#\CARON #\Return #\Linefeed #\7))
    (test :iso-8859-2 '(#xb7 #x0d #x0a #x37))
    (test (:iso-8859-2 :newline :lf) '(#xb7 #x0d #x0a #x37))
    (test (:iso-8859-2 :newline :cr) '(#xb7 #x0d #x0d #x37))
    (test (:iso-8859-2 :newline :crlf) '(#xb7 #x0d #x0d #x0a #x37))))

(macrolet ((output-test (chars outxf expected &environment env)
             `(progn
                (with-open-file (s *test-path* :element-type 'character
                                   :external-format ',outxf
                                   :direction :output :if-exists :supersede)
                  (handler-bind ((sb-int:character-encoding-error
                                  (lambda (c)
                                    (let ((restart (find-restart 'sb-impl::output-nothing c)))
                                      (invoke-restart restart)))))
                    (write-sequence ,chars s)))
                (with-test (:name (,(macroexpand 'name env) :file ,outxf))
                  (with-open-file (s *test-path* :element-type '(unsigned-byte 8))
                    (let* ((vector (make-array 20 :element-type '(unsigned-byte 8)))
                           (count (read-sequence vector s)))
                      (assert (equal (map 'list 'identity (subseq vector 0 count)) ,expected)))))
                (with-test (:name (,(macroexpand 'name env) :octets ,outxf))
                  (handler-bind ((sb-int:character-encoding-error
                                  (lambda (c) (use-value nil c))))
                    (let* ((string (coerce chars 'string))
                           (octets (sb-ext:string-to-octets string :external-format ',outxf)))
                      (assert (typep octets '(simple-array (unsigned-byte 8) 1)))
                      (assert (equal (coerce octets 'list) ,expected)))))))
           (with-output-characters ((id chars) &body body)
             `(let ((chars ,chars))
                (symbol-macrolet ((name ,id))
                  (macrolet ((test (outxf expected)
                               `(output-test chars ,outxf ,expected)))
                    ,@body)))))
  (with-output-characters ((:output :invalid :lf) (list #\CARON (code-char 512) #\Linefeed #\7))
    (test :iso-8859-2 '(#xb7 #x0a #x37))
    (test (:iso-8859-2 :replacement #\?) '(#xb7 #x3f #x0a #x37))
    (test (:iso-8859-2 :newline :lf) '(#xb7 #x0a #x37))
    (test (:iso-8859-2 :newline :lf :replacement #\?) '(#xb7 #x3f #x0a #x37))
    (test (:iso-8859-2 :newline :cr) '(#xb7 #x0d #x37))
    (test (:iso-8859-2 :newline :cr :replacement #\?) '(#xb7 #x3f #x0d #x37))
    (test (:iso-8859-2 :newline :crlf) '(#xb7 #x0d #x0a #x37))
    (test (:iso-8859-2 :newline :crlf :replacement #\?) '(#xb7 #x3f #x0d #x0a #x37))))

(macrolet ((test (inxf expected &environment env)
             `(with-test (:name (,(macroexpand 'name env) ,inxf))
                (with-open-file (s *test-path* :external-format ',inxf)
                  (let* ((string (make-string 10000))
                         (count (read-sequence string s)))
                    (assert (equal (map 'list 'char-code (subseq string 0 count)) ,expected))))))
           (with-test-file ((id bytes) &body body)
             `(progn
                (with-open-file (s *test-path* :element-type '(unsigned-byte 8)
                                   :direction :output :if-exists :supersede)
                  (dolist (byte ,bytes)
                    (write-byte byte s)))
                (symbol-macrolet ((name ,id))
                  ,@body)))
           (tests (size)
             `(progn
                (with-test-file ((:input :lf ,size) (contents ,size '(#x0a)))
                  (test :iso-8859-2 (contents ,size '(10)))
                  (test (:iso-8859-2 :newline :lf) (contents ,size '(10)))
                  (test (:iso-8859-2 :newline :cr) (contents ,size '(10)))
                  (test (:iso-8859-2 :newline :crlf) (contents ,size '(10))))
                (with-test-file ((:input :cr ,size) (contents ,size '(#x0d)))
                  (test :iso-8859-2 (contents ,size '(13)))
                  (test (:iso-8859-2 :newline :lf) (contents ,size '(13)))
                  (test (:iso-8859-2 :newline :cr) (contents ,size '(10)))
                  (test (:iso-8859-2 :newline :crlf) (contents ,size '(13))))
                (with-test-file ((:input :crlf ,size) (contents ,size '(#x0d #x0a)))
                  (test :iso-8859-2 (contents ,size '(13 10)))
                  (test (:iso-8859-2 :newline :lf) (contents ,size '(13 10)))
                  (test (:iso-8859-2 :newline :cr) (contents ,size '(10 10)))
                  (test (:iso-8859-2 :newline :crlf) (contents ,(1- size) '(10)))))))
  (flet ((contents (size nl)
           (let ((bytes (make-array size :initial-element #x61)))
             (loop for x in nl
                   for j from (- (length bytes) (length nl))
                   do (setf (aref bytes j) x))
             (coerce bytes 'list))))
    (tests 2)

    (with-test (:name :ansi-stream-cin-buffer-length)
      (assert (= sb-impl::+ansi-stream-in-buffer-length+ 512)))

    (tests 511)
    (tests 512)
    (tests 513)

    ;; +ANSI-STREAM-IN-BUFFER-EXTRA+ is possibly also relevant.  Can't
    ;; test for it as the constant gets shaken out, but it's currently
    ;; 4.
    (tests 515)
    (tests 516)
    (tests 517)

    (with-test (:name :fd-stream-bytes-per-buffer)
      (assert (= sb-impl::+bytes-per-buffer+ 8192)))

    (tests 8190)
    (tests 8191)
    (tests 8192)
    (tests 8193)
    (tests 8194)))

(macrolet ((test (inxf expected &environment env)
             `(progn
                (with-test (:name (,(macroexpand 'name env) ,inxf))
                  (with-open-file (s *test-path* :external-format ',inxf)
                    (let ((actual
                           (cons (file-position s)
                                 (loop for char = (read-char s nil nil)
                                       while char
                                       collect (file-position s)))))
                      (assert (equal actual ,expected)))))
                (with-test (:name (,(macroexpand 'name env) unread-char ,inxf))
                  (with-open-file (s *test-path* :external-format ',inxf)
                    (assert (sb-impl::ansi-stream-cin-buffer s))
                    (let ((actual (loop for char = (read-char s nil nil)
                                        if (null char) collect (file-position s) and do (loop-finish)
                                        do (unread-char char s)
                                        collect (file-position s)
                                        do (read-char s))))
                      (assert (equal actual ,expected)))))
                (with-test (:name (,(macroexpand 'name env) unread-char :io ,inxf))
                  (with-open-file (s *test-path* :external-format ',inxf
                                     :direction :io :if-exists :overwrite)
                    ;; if we reinstate in character buffers for :io character streams,
                    ;; make a stream that is unbuffered some other way
                    (assert (not (sb-impl::ansi-stream-cin-buffer s)))
                    (let ((actual (loop for char = (read-char s nil nil)
                                        if (null char) collect (file-position s) and do (loop-finish)
                                        do (unread-char char s)
                                        collect (file-position s)
                                        do (read-char s))))
                      (assert (equal actual ,expected)))))))
           (with-test-file ((id bytes) &body body)
             `(progn
                (with-open-file (s *test-path* :element-type '(unsigned-byte 8)
                                   :direction :output :if-exists :supersede)
                  (dolist (byte ,bytes)
                    (write-byte byte s)))
                (symbol-macrolet ((name ,id))
                  ,@body))))
  (with-test-file ((file-position :lf) '(#xb7 #x0a #x37 #x38 #x0a #x39 #x3a #x0a #x3b))
    (test :iso-8859-2 (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :lf) (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :cr) (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :crlf) (loop for i from 0 to 9 collect i)))
  (with-test-file ((file-position :cr) '(#xb7 #x0d #x37 #x38 #x0d #x39 #x3a #x0d #x3b))
    (test :iso-8859-2 (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :lf) (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :cr) (loop for i from 0 to 9 collect i))
    (test (:iso-8859-2 :newline :crlf) (loop for i from 0 to 9 collect i)))
  (with-test-file ((file-position :crlf) '(#xb7 #x0d #x0a #x37 #x38 #x0d #x0a #x39 #x3a #x0d #x0a #x3b))
    (test :iso-8859-2 (loop for i from 0 to 12 collect i))
    (test (:iso-8859-2 :newline :lf) (loop for i from 0 to 12 collect i))
    (test (:iso-8859-2 :newline :cr) (loop for i from 0 to 12 collect i))
    (test (:iso-8859-2 :newline :crlf) '(0 1 3 4 5 7 8 9 11 12))))

(macrolet ((output-test (chars outxf expected &environment env)
             `(progn
                (with-test (:name (,(macroexpand 'name env) file-string-length ,outxf))
                  (let ((string (coerce ,chars 'string)))
                    (with-open-file (s *test-path* :element-type 'character
                                       :external-format ',outxf
                                       :direction :output :if-exists :supersede)
                      (handler-bind ((sb-int:character-encoding-error
                                      (lambda (c)
                                        (let ((restart (find-restart 'sb-impl::output-nothing c)))
                                          (invoke-restart restart)))))
                        (let ((pos (file-position s))
                              (len (file-string-length s string)))
                          (let ((actual
                                 (loop for index from 0 below (length string)
                                       for char = (char string index)
                                       for thislen = (file-string-length s char)
                                       for thisstringlen = (file-string-length s (subseq string index))
                                       if (null thisstringlen) do (assert (some 'null (subseq ,expected index))) else do (assert (notany 'null (subseq ,expected index)))
                                       collect thislen
                                       if (and (null len) thisstringlen) do (setf len (+ pos thisstringlen))
                                       if thisstringlen do (assert (= (+ pos thisstringlen) len))
                                       do (write-char char s)
                                       if thislen do (assert (= (+ pos thislen) (file-position s)))
                                       do (setf pos (file-position s)))))
                            (assert (equal actual ,expected))))))))))
           (with-output-characters ((id chars) &body body)
             `(let ((chars ,chars))
                (symbol-macrolet ((name ,id))
                  (macrolet ((test (outxf expected)
                               `(output-test chars ,outxf ,expected)))
                    ,@body)))))
  (with-output-characters ((:output :lf) (list #\5 #\Linefeed #\7))
    (test :iso-8859-2 '(1 1 1))
    (test (:iso-8859-2 :newline :lf) '(1 1 1))
    (test (:iso-8859-2 :newline :cr) '(1 1 1))
    (test (:iso-8859-2 :newline :crlf) '(1 2 1)))
  (with-output-characters ((:output :invalid :lf) (list #\5 (code-char #xa1) #\Linefeed #\7))
    ;; A sufficiently-smart streams implementation could statically determine the lengths
    ;; of replacement characters given as part of the external format
    (test :iso-8859-2 '(1 nil 1 1))
    (test (:iso-8859-2 :replacement #\?) '(1 nil 1 1))
    (test (:iso-8859-2 :newline :lf) '(1 nil 1 1))
    (test (:iso-8859-2 :newline :lf :replacement #\?) '(1 nil 1 1))
    (test (:iso-8859-2 :newline :cr) '(1 nil 1 1))
    (test (:iso-8859-2 :newline :cr :replacement #\?) '(1 nil 1 1))
    (test (:iso-8859-2 :newline :crlf) '(1 nil 2 1))
    (test (:iso-8859-2 :newline :crlf :replacement #\?) '(1 nil 2 1))))

(delete-file *test-path*)