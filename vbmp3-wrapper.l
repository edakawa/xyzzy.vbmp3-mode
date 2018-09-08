;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-wrapper.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-wrapper --- Wrapper of vbmp3-ffi for vbmp3-mode

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Commentary:

;; This is wrapper module of vbmp3-ffi for safety.  If you need VBMP3.DLL
;; function, please choose in this module.

;;; Code:

(provide "vbmp3/vbmp3-wrapper")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "vbmp3/vbmp3-ffi")
  (use-package "vbmp3"))


;;; Variable

(defvar *vbmp3-init* nil)
(defvar *vbmp3-current-open-pathname* nil)

(defvar *vbmp3-input-info* nil)

(defvar *vbmp3-tmp-tag-info-buffer*    (make-TAG_INFO))
(defvar *vbmp3-tmp-tag-info-11-buffer* (make-TAG_INFO_11))
(defvar *vbmp3-tmp-mpeg-info-buffer*   (make-MPEG_INFO))

(defconstant +vbmp3-state-before-open-file+ -1)
(defconstant +vbmp3-state-stop+              0)
(defconstant +vbmp3-state-playing+           1)
(defconstant +vbmp3-state-pause+             2)

(defconstant +vbmp3-file-type-standard-mp3+   0)
(defconstant +vbmp3-file-type-riff-wave+      1)
(defconstant +vbmp3-file-type-riff-mp3+       2)
(defconstant +vbmp3-file-type-id3-v2+         4)
(defconstant +vbmp3-file-type-mac-header+     8)
(defconstant +vbmp3-file-type-id3-v1+        16)
(defconstant +vbmp3-file-type-lyrics3-v2.00+ 32)
(defconstant +vbmp3-file-type-standard-wave+ 64)


;;; Utility Function

(defun %vbmp3-true-p (rc)
  (= rc 1))

(defun %vbmp3-false-p (rc)
  (or (= rc 0)
      (= rc -1)))

(defun %vbmp3-init-called-p ()
  (eq t *vbmp3-init*))

(defun %vbmp3-file-opened-p ()
  (not (null *vbmp3-current-open-pathname*)))

(defun %%vbmp3-current-state ()
    (multiple-value-bind (state sec)
	(vbmp3-get-state)
      state))

(defun %vbmp3-playing-p (&aux (state (%%vbmp3-current-state)))
  (= state +vbmp3-state-playing+))

(defun %vbmp3-stop-p (&aux (state (%%vbmp3-current-state)))
  (= state +vbmp3-state-stop+))

(defun %vbmp3-pause-p (&aux (state (%%vbmp3-current-state)))
  (= state +vbmp3-state-pause+))

(defun %vbmp3-wrapper-error (msg)
  (message-box msg "ERROR VBMP3-WRAPPER" '(:ok :exclamation)))


;;; Wrapper Function (via vbmp3-ffi)

(defun vbmp3-init ()
  (unless (%vbmp3-init-called-p)
    (when (%vbmp3-true-p (vbmp3:vbmp3_init))
      (setq *vbmp3-init*       t
	    *vbmp3-input-info* (make-InputInfo)))))

(defun vbmp3-free ()
  (when (%vbmp3-init-called-p)
    (vbmp3-close)
    (when (%vbmp3-true-p (vbmp3:vbmp3_free))
      (vbmp3-rem-input-info-prop)
      (setq *vbmp3-init*       nil
	    *vbmp3-input-info* nil))))

(defun vbmp3-open (pathname)
  (when (and (%vbmp3-init-called-p)
	     (stringp pathname)
	     (string-equal "mp3" (pathname-type pathname))
	     (>= (vbmp3-get-file-type pathname) 0))
    (when (%vbmp3-playing-p)
      (vbmp3:vbmp3_close))
    (when (%vbmp3-true-p (vbmp3:vbmp3_open (si:make-string-chunk pathname) *vbmp3-input-info*))
      (vbmp3-set-input-info-prop)
      (setq *vbmp3-current-open-pathname* pathname))))

(defun vbmp3-close ()
  (when (and (%vbmp3-file-opened-p)
	     (%vbmp3-true-p (vbmp3:vbmp3_close)))
      (vbmp3-rem-input-info-prop)
      (setq *vbmp3-current-open-pathname* nil)))

(defun vbmp3-play ()
  (when (and (%vbmp3-file-opened-p)
	     (%vbmp3-stop-p))
    (vbmp3:vbmp3_play)))

(defun vbmp3-stop ()
  (when (%vbmp3-playing-p)
    (vbmp3:vbmp3_stop)))

(defun vbmp3-pause ()
  (when (%vbmp3-playing-p)
    (vbmp3:vbmp3_pause)))

(defun vbmp3-restart ()
  (when (%vbmp3-pause-p)
    (vbmp3:vbmp3_restart)))

(defun vbmp3-get-version ()
  (when (%vbmp3-init-called-p)
    (vbmp3:vbmp3_getVersion)))

(defun vbmp3-reload ()
  (when (%vbmp3-init-called-p)
    (vbmp3:vbmp3_reload)))

(defun vbmp3-set-pitch (pitch)
  (when (%vbmp3-init-called-p)
    (vbmp3:vbmp3_setPitch pitch)))

(defun vbmp3-get-pitch ()
  (when (%vbmp3-init-called-p)
    (vbmp3:vbmp3_getPitch)))

(defun vbmp3-set-step-pitch (pitch frames)
  (when (%vbmp3-file-opened-p)
    (vbmp3:vbmp3_setStepPitch pitch frames)))

(defun vbmp3-get-file-type (pathname)
  (when (and (%vbmp3-init-called-p)
	     (stringp pathname))
    (vbmp3:vbmp3_getFileType (si:make-string-chunk pathname))))

(defun vbmp3-seek (sec)
  (when (%vbmp3-file-opened-p)
    (let ((total-sec (get '*vbmp3-input-info* 'time)))
      (if (and (>= sec 0)
	       (<= sec total-sec))
	  (vbmp3:vbmp3_seek (floor sec))))))

(defun vbmp3-set-soft-volume (left right)
  (when (and (%vbmp3-init-called-p)
	     (integerp left)
	     (integerp right))
    (let ((left  (cond ((< left  0) 0) ((> left  100) 100) (t left)))
	  (right (cond ((< right 0) 0) ((> right 100) 100) (t right))))
      (vbmp3:vbmp3_setSoftVolume left right))))

(defun vbmp3-get-soft-volume ()
  (when (%vbmp3-init-called-p)
      (let ((left  (si:make-chunk nil 4))
	    (right (si:make-chunk nil 4)))
	(si:pack-int32 left  0 0)
	(si:pack-int32 right 0 0)
	(vbmp3:vbmp3_getSoftVolume left right)
	(values (si:unpack-int32 left  0)
		(si:unpack-int32 right 0)))))

(defun vbmp3-get-state ()
  (if (%vbmp3-file-opened-p)
      (let ((sec (si:make-chunk nil 4)))
	(si:pack-int32 sec 0 0)
	(let ((state (vbmp3:vbmp3_getState sec)))
	  (values state (si:unpack-int32 sec 0))))
    (values +vbmp3-state-before-open-file+ 0)))

(defun vbmp3-set-equalizer (60Hz 170Hz 310Hz 600Hz 1KHz 3KHz 6KHz 12KHz 14KHz 16KHz)
  (when (%vbmp3-init-called-p)
    (when (every #'(lambda (Hz) (and (integerp Hz) (>= 120 Hz -120)))
		 `(,60Hz ,170Hz ,310Hz ,600Hz ,1KHz ,3KHz ,6KHz ,12KHz ,14KHz ,16KHz))
      (let ((e (vbmp3:make-EQUALIZER)))
	(setf (vbmp3:EQUALIZER-60Hz  e)  60Hz
	      (vbmp3:EQUALIZER-170Hz e) 170Hz
	      (vbmp3:EQUALIZER-310Hz e) 310Hz
	      (vbmp3:EQUALIZER-600Hz e) 600Hz
	      (vbmp3:EQUALIZER-1KHz  e)  1KHz
	      (vbmp3:EQUALIZER-3KHz  e)  3KHz
	      (vbmp3:EQUALIZER-6KHz  e)  6KHz
	      (vbmp3:EQUALIZER-12KHz e) 12KHz
	      (vbmp3:EQUALIZER-14KHz e) 14KHz
	      (vbmp3:EQUALIZER-16KHz e) 16KHz)
	(vbmp3:vbmp3_setEqualizer e)))))

(defun vbmp3-set-tag-info-ex (pathname &key track artist album year comment genre-name genre track-no)
  (flet ((shorten (n str)
	   (if (stringp str)
	       (if (>= n (count-column str))
		   str
		 (do* ((tail (1- (length str)) (1- tail))
		       (ret (subseq str 0 tail) (subseq str 0 tail)))
		     ((>= n (count-column ret)) ret)))
	     ""))
	 (check-id3-v1 (&aux (ftype (vbmp3-get-file-type pathname)))
	   (and (zerop (logand ftype +vbmp3-file-type-riff-wave+))
		(zerop (logand ftype +vbmp3-file-type-riff-mp3+))
		(zerop (logand ftype +vbmp3-file-type-id3-v2+))
		(zerop (logand ftype +vbmp3-file-type-mac-header+))
		(zerop (logand ftype +vbmp3-file-type-lyrics3-v2.00+))
		(zerop (logand ftype +vbmp3-file-type-standard-wave+)))))
      (when (and (%vbmp3-init-called-p)
		 (check-id3-v1))
	(multiple-value-bind (tag-info dummy)
	    (vbmp3-get-file-info pathname)
	  (unless (or (null tag-info) (null dummy))
	    (when track      (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szTrackName)  (shorten 29 track)))
	    (when artist     (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szArtistName) (shorten 29 artist)))
	    (when album      (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szAlbumName)  (shorten 29 album)))
	    (when year       (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szYear)       (shorten  4 year)))
	    (when comment    (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szComment)    (shorten 28 comment)))
	    (when genre-name (si:pack-string tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szGenreName)  (shorten 29 genre-name)))
	    (when genre      (setf (TAG_INFO_11-genre   tag-info) (cond ((not (integerp genre)) 0)    ((> genre 255) 255)    ((> 0 genre) 0)     (t genre))))
	    (when track-no   (setf (TAG_INFO_11-trackNo tag-info) (cond ((not (integerp track-no)) 0) ((> track-no 255) 255) ((> 0 track-no) -1) (t track-no))))
	    (let ((tag-set-p (and (%vbmp3-playing-p)
				  (string-equal pathname *vbmp3-current-open-pathname*))))
	      (%vbmp3-true-p (vbmp3_setTagInfoEX (si:make-string-chunk pathname) tag-info (if tag-set-p 1 0) 1))))))))

(defun vbmp3-get-genre (no)
  (when (and (integerp no)
	     (>= 255 no 0))
    (setf (TAG_INFO-genre *vbmp3-tmp-tag-info-buffer*) no)
    (when (%vbmp3-true-p (vbmp3_getGenre *vbmp3-tmp-tag-info-buffer*))
      (si:unpack-string *vbmp3-tmp-tag-info-buffer* (c:c-struct-offset-of TAG_INFO vbmp3::szGenreName)))))

(defun vbmp3-get-file-info (pathname)
  (when (and (%vbmp3-init-called-p)
	     (stringp pathname)
	     (string-equal "mp3" (pathname-type pathname))
	     (>= (vbmp3-get-file-type pathname) 0))
    (when (%vbmp3-true-p (vbmp3_getFileInfo (si:make-string-chunk pathname) *vbmp3-tmp-tag-info-11-buffer* *vbmp3-tmp-mpeg-info-buffer*))
      (when (%vbmp3-true-p (vbmp3_getFileTagInfoEX (si:make-string-chunk pathname) *vbmp3-tmp-tag-info-11-buffer*))
	(values *vbmp3-tmp-tag-info-11-buffer* *vbmp3-tmp-mpeg-info-buffer*)))))

(defun vbmp3-cut-id3-v2 (pathname)
  (when (and (%vbmp3-init-called-p)
	     (stringp pathname))
    (%vbmp3-true-p (vbmp3_cutID3v2 (si:make-string-chunk pathname)))))

(defun vbmp3-set-input-info-prop ()
  (when (eq (type-of *vbmp3-input-info*) 'system:chunk)
    (setf (get '*vbmp3-input-info* 'track)    (si:unpack-string *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::szTrackName))
	  (get '*vbmp3-input-info* 'artist)   (si:unpack-string *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::szArtistName))
	  (get '*vbmp3-input-info* 'channels) (si:unpack-int32  *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::channels))
	  (get '*vbmp3-input-info* 'bit)      (si:unpack-int32  *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::bitRate))
	  (get '*vbmp3-input-info* 'sampling) (si:unpack-int32  *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::samplingRate))
	  (get '*vbmp3-input-info* 'time)     (si:unpack-int32  *vbmp3-input-info* (c:c-struct-offset-of vbmp3:InputInfo vbmp3::totalSec)))))

(defun vbmp3-rem-input-info-prop ()
  (when (%vbmp3-file-opened-p)
    (setf (get '*vbmp3-input-info* 'track)    ""
	  (get '*vbmp3-input-info* 'artist)   ""
	  (get '*vbmp3-input-info* 'channels) 0
	  (get '*vbmp3-input-info* 'bit)      0
	  (get '*vbmp3-input-info* 'sampling) 0
	  (get '*vbmp3-input-info* 'time)     0)))
