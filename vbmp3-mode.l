;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-mode.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-mode --- Main module

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Commentary:

;; This is vbmp3-mode main module.

;;; Requirement:

;; VBMP3.DLL 1.6.1.5 or later.
;; SQLite ODBC Driver 0.85 or later.

;;; Installation:

;; 1. Please move all files in vbmp3-mode.zip to your site-lisp directory.
;; 2. Please add following expression to your .xyzzy file.
;;     (require "vbmp3/vbmp3-mode")
;; 3. End.

;; If you don't have VBMP3.DLL, please download from following URL.
;;     http://www.src.jpn.org/kei/download/

;; If you don't install SQLite ODBC Driver, please download from following URL.
;;     http://www.ch-werner.de/sqliteodbc/

;;; Key Binding:

;; o      open file
;; c      close opend file
;; p      play opened file
;; RET    play on playlist current line file
;; SPC    stop playing
;; P      pause playing
;; R      restart pausing
;; TAB    change play speed
;; n      play next file on playlist
;; b      play previous file on playlist
;; S      seek time
;; +      seek time 1 second after
;; -      seek time 1 second before
;; r      toggle repeat mode
;; s      toggle shuffle mode
;; v      change volume
;; 1      sort artist field
;; 2      sort track field
;; 3      sort time field
;; 4      sort file field
;; e      popup preset equalizer
;; ESC    modify ID3v1 tag on playlist current line file
;; h      display help
;; q      quit vbmp3-mode
;; a      choose directory add to playlist
;; A      choose file add to playlist

;;; Acknowledgement:

;; mimiz
;;     Reported can't open mp3 file problem on vbmp3-open.
;;     Suggestion on vbmp3-db.

;;; Code:

(provide "vbmp3/vbmp3-mode")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "ole")
  (require "cmu_loop")
  (require "vbmp3/vbmp3-wrapper")
  (require "vbmp3/vbmp3-playlist")
  (require "vbmp3/vbmp3-board")
  (require "vbmp3/vbmp3-info")
  (require "vbmp3/vbmp3-db"))

(defun vbmp3-mode ()
  (interactive)
  (vbmp3-init)
  (when (> 161 (vbmp3-get-version))
    (%vbmp3-mode-error "VBMP3.DLL が古いので VBMP3 改に更新してください")
    (vbmp3-mode-quit)
    (return-from vbmp3-mode nil))
  (new-pseudo-frame +vbmp3-mode-pseudo-frame-name+)
  (vbmp3-playlist-startup)
  (vbmp3-board-startup)
  (vbmp3-info-startup)
  (let ((old-playlist-pathname (merge-pathnames "site-lisp/vbmp3/playlist.l" (si:system-root))))
    (when (and (file-readable-p old-playlist-pathname)
	       (zerop (file-length *vbmp3-mode-playlist-pathname*))
	       (yes-no-or-cancel-p "playlist のデータをインポートしますか?"))
    (handler-case
	(unwind-protect
	    (let ((lsls nil))
	      (with-open-file (in old-playlist-pathname :direction :input)
		(setf lsls (read in nil)))
	      (vbmp3-db-execute "BEGIN;")
	      (dolist (ls lsls)
		(message "Reading...~A" (getf ls :pathname))
		(vbmp3-db-add-playlist (getf ls :pathname))))
	  (vbmp3-db-execute "COMMIT;"))
      (error (c)
	(vbmp3-db-execute "ROLLBACK;")
	(vbmp3-db-error "playlist のインポートに失敗しました")))))
  (vbmp3-board-insert)
  (run-hooks '*vbmp3-mode-hook*))

(defvar *vbmp3-mode-map* nil)
(unless *vbmp3-mode-map*
  (setq *vbmp3-mode-map* (make-sparse-keymap))
  (define-key *vbmp3-mode-map* #\o      'vbmp3-mode-open)
  (define-key *vbmp3-mode-map* #\c      'vbmp3-mode-close)
  (define-key *vbmp3-mode-map* #\p      'vbmp3-mode-play)
  (define-key *vbmp3-mode-map* #\RET    'vbmp3-mode-playlist-play)
  (define-key *vbmp3-mode-map* #\SPC    'vbmp3-mode-stop)
  (define-key *vbmp3-mode-map* #\P      'vbmp3-mode-pause)
  (define-key *vbmp3-mode-map* #\R      'vbmp3-mode-restart)
  (define-key *vbmp3-mode-map* #\Tab    'vbmp3-mode-set-pitch)
  (define-key *vbmp3-mode-map* #\n      'vbmp3-mode-next)
  (define-key *vbmp3-mode-map* #\b      'vbmp3-mode-prev)
  (define-key *vbmp3-mode-map* #\S      'vbmp3-mode-seek)
  (define-key *vbmp3-mode-map* #\+      'vbmp3-mode-forward)
  (define-key *vbmp3-mode-map* #\-      'vbmp3-mode-back)
  (define-key *vbmp3-mode-map* #\r      'vbmp3-mode-repeat-toggle)
  (define-key *vbmp3-mode-map* #\s      'vbmp3-mode-shuffle-toggle)
  (define-key *vbmp3-mode-map* #\v      'vbmp3-mode-set-volume)
  (define-key *vbmp3-mode-map* #\LBtnUp 'vbmp3-mode-left-press)
  (define-key *vbmp3-mode-map* #\RBtnUp 'vbmp3-mode-right-press)
  (define-key *vbmp3-mode-map* #\d      'vbmp3-playlist-delete-current-line)
  (define-key *vbmp3-mode-map* #\1      'vbmp3-playlist-sort-artist)
  (define-key *vbmp3-mode-map* #\2      'vbmp3-playlist-sort-track)
  (define-key *vbmp3-mode-map* #\3      'vbmp3-playlist-sort-time)
  (define-key *vbmp3-mode-map* #\4      'vbmp3-playlist-sort-file)
  (define-key *vbmp3-mode-map* #\e      'vbmp3-mode-popup-pre-set-equalizer)
  (define-key *vbmp3-mode-map* #\ESC    'vbmp3-mode-set-id3-v1.1)
  (define-key *vbmp3-mode-map* #\h      'vbmp3-mode-help)
  (define-key *vbmp3-mode-map* #\q      'vbmp3-mode-quit)
  (define-key *vbmp3-mode-map* #\a      'vbmp3-db-query-add-playlist-from-directory-name-dialog)
  (define-key *vbmp3-mode-map* #\A      'vbmp3-db-query-add-playlist-from-file-name-dialog))


;;; Variable

(defconstant +vbmp3-mode-line-update-interval+ 0.5)
(defconstant +vbmp3-mode-repeat-interval+      2)
(defconstant +vbmp3-mode-shuffle-interval+     2)
(defconstant +vbmp3-mode-pseudo-frame-name+    "vbmp3")
(defconstant +vbmp3-mode-open-label+           "OPEN")
(defconstant +vbmp3-mode-stop-label+           "STOP")
(defconstant +vbmp3-mode-repeat-label+         "REPEAT")
(defconstant +vbmp3-mode-shuffle-label+        "SHUFFLE")
(defconstant +vbmp3-mode-play-label+           "PLAY")
(defconstant +vbmp3-mode-pause-label+          "PAUSE")
(defconstant +vbmp3-mode-ready-label+          "READY")
(defconstant +vbmp3-mode-close-label+          "CLOSE")
(defconstant +vbmp3-mode-usage+                "o       ファイルを開く
c       ファイルを閉じる
p       開いたファイルを再生する
RET     プレイリストの現在行の mp3 ファイルを再生する
SPC     再生を停止する
P       再生を一時停止する
R       一時停止から再開する
TAB     再生速度を変更する
n       プレイリストの次のファイルを再生する
b       プレイリストの前のファイルを再生する
S       再生時間をシークする
+       再生時間を 1 秒後にシークする
-       再生時間を 1 秒前にシークする
r       リピート再生をトグルする
s       シャッフル再生をトグルする
v       ボリュームを設定する
1       Artist フィールドをソートする
2       Track フィールドをソートする
3       Time フィールドをソートする
4       File フィールドをソートする
e       プリセットイコライザを表示する
ESC     プレイリストの現在行の ID3 タグ (v1.1) を変更する
h       操作キーのヘルプを表示する
q       vbmp3-mode を終了する
a       プレイリストに追加するフォルダを選択する
A       プレイリストに追加するファイルを選択する")

(defvar *vbmp3-mode-line-format*           "Volume: %volume   Sound: %sound   Pitch: %pitch")
(defvar *vbmp3-mode-elapsed-time-count-up* nil)
(defvar *vbmp3-mode-board-type*            'artist)
(defvar *vbmp3-mode-hook*                  nil)

(defvar *vbmp3-mode-current-volume-left*    nil)
(defvar *vbmp3-mode-current-volume-right*   nil)
(defvar *vbmp3-mode-current-mode-line*      nil)
(defvar *vbmp3-mode-current-file-type*      nil)
(defvar *vbmp3-mode-last-open-directory*    nil)
(defvar *vbmp3-mode-last-open-file-name*    nil)
(defvar *vbmp3-mode-last-open-pathname*     nil)
(defvar *vbmp3-mode-current-sound-type*     "Normal")
(defvar *vbmp3-mode-line-update-active*     nil)
(defvar *vbmp3-mode-repeat-active*          nil)
(defvar *vbmp3-mode-shuffle-active*         nil)
(defvar *vbmp3-mode-current-status*         nil)
(defvar *vbmp3-mode-pause-time*             nil)
(defvar *vbmp3-mode-file-info*              nil)
(defvar *vbmp3-mode-pre-set-equalizer-list* `(("Normal"       . ,#'(lambda () (values   0   0   0   0   0   0   0   0   0   0)))
					      ("Rock"         . ,#'(lambda () (values  60  40  20   0 -20 -20   0  20  40  60)))
					      ("Pop"          . ,#'(lambda () (values  20  30  40  60  60  40  30  20   0   0)))
					      ("Classic"      . ,#'(lambda () (values   0   0   0   0   0   0 -23 -23 -23 -34)))
					      ("Live"         . ,#'(lambda () (values -17   0  14  20  20  18  14   8   8   8)))
					      ("Base Boost"   . ,#'(lambda () (values  60  60  40  30   0   0   0   0   0   0)))
					      ("Treble Boost" . ,#'(lambda () (values   0   0   0   0  20  30  40  60  60  60)))
					      ("Total Boost"  . ,#'(lambda () (values  60  60  60  60  60  60  60  60  60  60)))
					      ("Total Reduce" . ,#'(lambda () (values -60 -60 -60 -60 -60 -60 -60 -60 -60 -60)))))


;;; Macro

(defmacro aif (test-form then-form &optional else-form)
  `(let ((it ,test-form))
     (if it ,then-form ,else-form)))

(defmacro awhen (test-form &body body)
  `(aif ,test-form
       (progn ,@body)))


;;; Utility Function

(defun %vbmp3-mode-delete-buffer (buffer)
  (prog1 t
    (when (string= (buffer-name buffer) +vbmp3-mode-play-label+)
      (awhen (find-pseudo-frame +vbmp3-mode-pseudo-frame-name+)
	(delete-pseudo-frame it)
	(vbmp3-free)
	(%vbmp3-mode-reset-env)))))

(defun %vbmp3-mode-current-sec ()
  (multiple-value-bind (state sec)
      (vbmp3-get-state)
    sec))

(defun %%vbmp3-mode-current-state ()
  (multiple-value-bind (state sec)
      (vbmp3-get-state)
    state))

(defun %vbmp3-mode-before-open-file-p (&aux (state (%%vbmp3-mode-current-state)))
  (= state +vbmp3-state-before-open-file+))

(defun %vbmp3-mode-stop-p (&aux (state (%%vbmp3-mode-current-state)))
  (or (= state +vbmp3-state-stop+)
      (= state +vbmp3-state-before-open-file+)))

(defun %vbmp3-mode-playing-p (&aux (state (%%vbmp3-mode-current-state)))
  (= state +vbmp3-state-playing+))

(defun %vbmp3-mode-pause-p (&aux (state (%%vbmp3-mode-current-state)))
  (= state +vbmp3-state-pause+))

(defun %vbmp3-mode-open-file-p ()
  (not (null *vbmp3-mode-last-open-file-name*)))

(defun %vbmp3-mode-playlist-exist ()
  (not (null *vbmp3-mode-playlist*)))

(defun %vbmp3-mode-error (msg)
  (message-box msg "ERROR VBMP3-MODE" '(:ok :exclamation))
  nil)

(defun %vbmp3-mode-reload-current-file-type ()
  (setq *vbmp3-mode-current-file-type* (vbmp3-get-file-type *vbmp3-current-open-pathname*)))

(defun %vbmp3-mode-position-current-pathname ()
  (let ((ls (vbmp3-playlist-select-from-playlist :pathname)))
    (values (position *vbmp3-current-open-pathname*
		      (vbmp3-playlist-select-from-playlist :pathname)
		      :test #'equal)
	    ls)))

(defun %vbmp3-mode-repeat-p ()
  (not (null *vbmp3-mode-repeat-active*)))

(defun %vbmp3-mode-shuffle-p ()
  (not (null *vbmp3-mode-shuffle-active*)))

(defun %vbmp3-mode-disable-repeat ()
  (when *vbmp3-mode-repeat-active*
    (setq *vbmp3-mode-repeat-active* nil)
    (stop-timer 'vbmp3-mode-play)))

(defun %vbmp3-mode-enable-repeat ()
  (unless *vbmp3-mode-repeat-active*
    (setq *vbmp3-mode-repeat-active* t)
    (start-timer +vbmp3-mode-repeat-interval+ 'vbmp3-mode-play)))

(defun %vbmp3-mode-disable-shuffle ()
  (when *vbmp3-mode-shuffle-active*
    (setq *vbmp3-mode-shuffle-active* nil)
    (stop-timer '%vbmp3-mode-shuffle)))

(defun %vbmp3-mode-enable-shuffle ()
  (unless *vbmp3-mode-shuffle-active*
    (setq *vbmp3-mode-shuffle-active* t)
    (start-timer +vbmp3-mode-shuffle-interval+ '%vbmp3-mode-shuffle)))

(defun %vbmp3-mode-shuffle ()
  (when (and (%vbmp3-mode-stop-p)
	     (%vbmp3-mode-playlist-exist))
    (let* ((rnd (random (length *vbmp3-mode-playlist*)))
	   (pathname (getf (nth rnd *vbmp3-mode-playlist*) :pathname)))
      (when (vbmp3-mode-open pathname)
	(vbmp3-mode-play)))))

(defun %vbmp3-mode-line-update-toggle ()
  (setq *vbmp3-mode-line-update-active* (not *vbmp3-mode-line-update-active*))
  (if *vbmp3-mode-line-update-active*
      (start-timer +vbmp3-mode-line-update-interval+ '%vbmp3-mode-line-update)
    (stop-timer '%vbmp3-mode-line-update)))

(defun %vbmp3-mode-reset-env ()
  (when *vbmp3-mode-repeat-active*
    (vbmp3-mode-repeat-toggle))
  (when *vbmp3-mode-shuffle-active*
    (vbmp3-mode-shuffle-toggle))
  (when *vbmp3-mode-line-update-active*
    (%vbmp3-mode-line-update-toggle))
  (setq *vbmp3-mode-pause-time* nil
	*vbmp3-mode-last-open-file-name* nil))

(defun %vbmp3-mode-get-volume ()
  (unless (or *vbmp3-mode-current-volume-left*
	      *vbmp3-mode-current-volume-right*)
    (multiple-value-bind (L R)
	(vbmp3-get-soft-volume)
      (setq *vbmp3-mode-current-volume-left*  L
	    *vbmp3-mode-current-volume-right* R)))
  (format nil "~A ~A" *vbmp3-mode-current-volume-left* *vbmp3-mode-current-volume-right*))

(defun %vbmp3-mode-get-mode-line-format (&optional (any-format nil))
  (loop for (x . y) in `(("%file"        . ,*vbmp3-mode-last-open-file-name*)
			 ("%volume"      . ,(%vbmp3-mode-get-volume))
			 ("%pitch"       . ,(format nil "~,2F" (/ (vbmp3-get-pitch) 100)))
			 ("%sound"       . ,*vbmp3-mode-current-sound-type*)
			 ("%track"       . ,(get *vbmp3-mode-file-info* :track))
			 ("%artist"      . ,(get *vbmp3-mode-file-info* :artist))
			 ("%album"       . ,(get *vbmp3-mode-file-info* :album))
			 ("%year"        . ,(get *vbmp3-mode-file-info* :year))
			 ("%comment"     . ,(get *vbmp3-mode-file-info* :comment))
			 ("%genre-name"  . ,(get *vbmp3-mode-file-info* :genre-name))
			 ("%genre"       . ,(get *vbmp3-mode-file-info* :genre))
			 ("%track-no"    . ,(get *vbmp3-mode-file-info* :track-no))
			 ("%version"     . ,(get *vbmp3-mode-file-info* :version))
			 ("%layer"       . ,(get *vbmp3-mode-file-info* :layer))
			 ("%crc-disable" . ,(get *vbmp3-mode-file-info* :crc-disable))
			 ("%extension"   . ,(get *vbmp3-mode-file-info* :extension))
			 ("%mode"        . ,(get *vbmp3-mode-file-info* :mode))
			 ("%copyright"   . ,(get *vbmp3-mode-file-info* :copyright))
			 ("%original"    . ,(get *vbmp3-mode-file-info* :original))
			 ("%emphasis"    . ,(get *vbmp3-mode-file-info* :emphasis))
			 ("%channels"    . ,(get *vbmp3-mode-file-info* :channels))
			 ("%bit"         . ,(get *vbmp3-mode-file-info* :bit))
			 ("%sampling"    . ,(get *vbmp3-mode-file-info* :sampling))
			 ("%file-size"   . ,(get *vbmp3-mode-file-info* :file-size))
			 ("%frames"      . ,(get *vbmp3-mode-file-info* :frames))
			 ("%time"        . ,(get *vbmp3-mode-file-info* :time)))
        with str = (or any-format *vbmp3-mode-line-format*)
        do (setq str (substitute-string str x (if (numberp y) (write-to-string y) y)))
        finally (return str)))

(defun %vbmp3-mode-update-play-mode-label (&optional (state nil))
  (setq *vbmp3-mode-current-status* (if state
					state
				      (cond ((%vbmp3-mode-stop-p)    (cond ((%vbmp3-mode-open-file-p) +vbmp3-mode-open-label+)
									   (t                         +vbmp3-mode-stop-label+)))
					    ((%vbmp3-mode-playing-p) (cond ((%vbmp3-mode-repeat-p)    +vbmp3-mode-repeat-label+)
									   ((%vbmp3-mode-shuffle-p)   +vbmp3-mode-shuffle-label+)
									   (t                         +vbmp3-mode-play-label+)))
					    ((%vbmp3-mode-pause-p)                                    +vbmp3-mode-pause-label+)
					    (t                                                        +vbmp3-mode-ready-label+)))))

(defun %vbmp3-mode-line-update ()
  (unless (minibuffer-window-p (selected-window))
    (let ((last-selected-buffer (selected-buffer)))
      (switch-to-buffer +vbmp3-mode-playlist-buffer+)
      (%vbmp3-mode-update-play-mode-label)
      (multiple-value-bind (state sec)
	  (vbmp3-get-state)
	(let* ((sec (if *vbmp3-mode-pause-time* *vbmp3-mode-pause-time* sec))
	       (sec (if *vbmp3-mode-elapsed-time-count-up* sec (- (get '*vbmp3-input-info* 'time) sec)))
	       (m (floor (/ sec 60)))
	       (minute (mod m 60))
	       (second (mod sec 60)))
	  (setq mode-line-format (format nil "vbmp3 [~2,'0D:~2,'0D]   <~A>   ~A"
					 minute second
					 *vbmp3-mode-current-status*
					 *vbmp3-mode-current-mode-line*))))
      (switch-to-buffer last-selected-buffer)
      (update-mode-line)
      (refresh-screen))))

(defun %vbmp3-mode-reload-file-info (&optional (pathname nil))
  (let ((lsls (format nil
		      "(~{(:~A . ~S)~})"
		      (vbmp3-mode-get-file-info (or pathname
						    *vbmp3-mode-last-open-pathname*)))))
	(loop for (ind . val) in (read-from-string lsls)
	      do (setf (get *vbmp3-mode-file-info* ind) val))))

(defun %vbmp3-mode-set-equalizer-normal (&aux (mode "Normal"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-rock (&aux (mode "Rock"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-pop (&aux (mode "Pop"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-classic (&aux (mode "Classic"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-live (&aux (mode "Live"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-base-boost (&aux (mode "Base Boost"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-treble-boost (&aux (mode "Treble Boost"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-total-boost (&aux (mode "Total Boost"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun %vbmp3-mode-set-equalizer-total-reduce (&aux (mode "Total Reduce"))
  (interactive)
  (multiple-value-call #'vbmp3-mode-set-equalizer
    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
    mode))

(defun vbmp3-mode-left-press ()
  (interactive)
  (goto-last-mouse-point)
  (let ((click (mod *last-mouse-click-count* 6)))
    (when (= click 2)
      (case buffer-mode
	(vbmp3-mode
	 (vbmp3-mode-playlist-play))
	(vbmp3-board
	 (%vbmp3-board-left-press))))))

(defun vbmp3-mode-right-press ()
  (interactive)
  (let ((cbufname (buffer-name (selected-buffer))))
    (cond ((string= cbufname +vbmp3-mode-board-buffer+)
	   (track-popup-menu *vbmp3-board-popup-menu*
			     :button1))
	  ((string= cbufname +vbmp3-mode-playlist-buffer+)
	   (track-popup-menu *vbmp3-playlist-popup-menu*
			     :button1))
	  ((string= cbufname +vbmp3-mode-info-left-buffer+)
	   (track-popup-menu *vbmp3-info-left-popup-menu*
			     :button1)))))

(defun %vbmp3-mode-up-volume-by-20 ()
  (interactive)
  (vbmp3-mode-set-volume (+ *vbmp3-mode-current-volume-left*  20)
			 (+ *vbmp3-mode-current-volume-right* 20)))
			 
(defun %vbmp3-mode-down-volume-by-20 ()
  (interactive)
  (vbmp3-mode-set-volume (- *vbmp3-mode-current-volume-left*  20)
			 (- *vbmp3-mode-current-volume-right* 20)))

(defun %vbmp3-mode-max-volume ()
  (interactive)
  (vbmp3-mode-set-volume 100 100))

(defun %vbmp3-mode-min-volume ()
  (interactive)
  (vbmp3-mode-set-volume 0 0))

(defun %vbmp3-mode-reset-pitch ()
  (interactive)
  (vbmp3-mode-set-pitch 1))

(defun %vbmp3-mode-up-pitch-by-0.2 ()
  (interactive)
  (let ((pitch (vbmp3-get-pitch)))
    (vbmp3-mode-set-pitch (* 1.2 (/ pitch 100)))))

(defun %vbmp3-mode-down-pitch-by-0.2 ()
  (interactive)
  (let ((pitch (vbmp3-get-pitch)))
    (vbmp3-mode-set-pitch (* 0.8 (/ pitch 100)))))

(defun %vbmp3-mode-max-pitch ()
  (interactive)
  (vbmp3-mode-set-pitch 3.00))

(defun %vbmp3-mode-min-pitch ()
  (interactive)
  (vbmp3-mode-set-pitch 0.20))


;;; Interface Function (via vbmp3-wrapper)

(defun vbmp3-mode-open (pathname)
  (interactive (list (read-file-name "Open File: " :default *vbmp3-mode-last-open-directory*)))
  (if (vbmp3-open pathname)
      (prog1 t
	(%vbmp3-mode-reload-file-info pathname)
	(setq *vbmp3-mode-last-open-pathname*  pathname
	      *vbmp3-mode-last-open-directory* (directory-namestring pathname)
	      *vbmp3-mode-last-open-file-name* (file-namestring pathname)
	      *vbmp3-mode-current-file-type*   (vbmp3-get-file-type pathname)
	      *vbmp3-mode-current-mode-line*   (%vbmp3-mode-get-mode-line-format)
	      *vbmp3-mode-pause-time*          nil)
	(vbmp3-info-insert-right-info)
	(vbmp3-info-insert-left-info)
	(when *vbmp3-mode-line-update-active*
	  (%vbmp3-mode-line-update-toggle))
	(%vbmp3-mode-line-update)
	(unless (member pathname
			(vbmp3-playlist-select-from-playlist :pathname)
			:test #'equal)
	  (vbmp3-playlist-add-playlist (vbmp3-playlist-make-input-info-tag pathname
									   (get '*vbmp3-input-info* 'artist)
									   (get '*vbmp3-input-info* 'track)
									   (get '*vbmp3-input-info* 'bit)
									   (get '*vbmp3-input-info* 'sampling)
									   (get '*vbmp3-input-info* 'time)))
	  (vbmp3-playlist-save-playlist)
	  (vbmp3-playlist-load-playlist)
	  (switch-to-buffer +vbmp3-mode-playlist-buffer+)
	  (delete-region (point-min) (point-max))
	  (vbmp3-playlist-insert-playlist)))
    (prog1 nil
      (%vbmp3-mode-error (concat pathname " が見つかりません")))))

(defun vbmp3-mode-close ()
  (interactive)
  (%vbmp3-mode-reset-env)
  (vbmp3-close)
  (vbmp3-rem-input-info-prop)
  (setq *vbmp3-mode-current-mode-line* "")
  (%vbmp3-mode-line-update))

(defun vbmp3-mode-play ()
  (interactive)
  (unless *vbmp3-mode-line-update-active*
    (%vbmp3-mode-line-update-toggle))
  (let ((r (%vbmp3-mode-repeat-p))
	(p (%vbmp3-mode-playing-p)))
    (cond ((and r p))
	  ((and r)
	   (vbmp3-info-update-right-mode-line)
	   (vbmp3-play))
	  ((and p)
	   (vbmp3-mode-open *vbmp3-current-open-pathname*)
	   (vbmp3-info-update-right-mode-line)
	   (vbmp3-play))
	  (t
	   (vbmp3-info-update-right-mode-line)
	   (vbmp3-play)))))

(defun vbmp3-mode-playlist-play ()
  (interactive)
  (when (> (current-line-number) 2)
    (aif (vbmp3-playlist-current-line-pathname)
	(progn
	  (vbmp3-mode-open it)
	  (vbmp3-mode-play))
      (%vbmp3-mode-error "mp3 が見当たりません"))))

(defun vbmp3-mode-stop ()
  (interactive)
  (when (%vbmp3-mode-playing-p)
    (%vbmp3-mode-reset-env)
    (vbmp3-stop)
    (%vbmp3-mode-line-update)))

(defun vbmp3-mode-pause ()
  (interactive)
  (setq *vbmp3-mode-pause-time* (%vbmp3-mode-current-sec))
  (vbmp3-pause))

(defun vbmp3-mode-restart ()
  (interactive)
  (when *vbmp3-mode-pause-time*
    (vbmp3-mode-seek *vbmp3-mode-pause-time*)
    (setq *vbmp3-mode-pause-time* nil)
    (vbmp3-restart)))

(defun vbmp3-mode-set-pitch (pitch)
  (interactive (list (read-from-string (read-string "Input pitch (3.00 >= pitch >= 0.20): ") nil)))
  (when (and (or (floatp pitch)
		 (integerp pitch))
	     (>= 3 pitch 0.20))
    (vbmp3-set-pitch (round (* 100 pitch)))
    (setq *vbmp3-mode-current-mode-line* (%vbmp3-mode-get-mode-line-format))
    (%vbmp3-mode-line-update)))

(defun vbmp3-mode-next ()
  (interactive)
  (when (and (%vbmp3-mode-open-file-p)
	     (%vbmp3-mode-playlist-exist))
    (cond ((%vbmp3-mode-repeat-p)
	   (vbmp3-mode-seek 0))
	  ((%vbmp3-mode-shuffle-p)
	   (vbmp3-mode-stop)
	   (%vbmp3-mode-enable-shuffle)
	   (%vbmp3-mode-shuffle))
	  (t
	   (multiple-value-bind (pos ls)
	       (%vbmp3-mode-position-current-pathname)
	     (vbmp3-mode-close)
	     (let ((nl (if (= pos (1- (length ls))) 0 (1+ pos))))
	       (vbmp3-mode-open (nth nl ls))
	       (vbmp3-mode-play)
	       (goto-line (+ 3 nl))))))))

(defun vbmp3-mode-prev ()
  (interactive)
  (when (and (%vbmp3-mode-open-file-p)
	     (%vbmp3-mode-playlist-exist))
    (cond ((%vbmp3-mode-repeat-p)
	   (vbmp3-mode-seek 0))
	  ((%vbmp3-mode-shuffle-p)
	   (vbmp3-mode-stop)
	   (%vbmp3-mode-enable-shuffle)
	   (%vbmp3-mode-shuffle))
	  (t
	   (multiple-value-bind (pos ls)
	       (%vbmp3-mode-position-current-pathname)
	     (vbmp3-mode-close)
	     (let ((pl (1- (if (zerop pos) (length ls) pos))))
	       (vbmp3-mode-open (nth pl ls))
	       (vbmp3-mode-play)
	       (goto-line (+ 3 pl))))))))

(defun vbmp3-mode-seek (sec)
  (interactive "nSeek(sec): ")
  (if (and (integerp sec)
	   (>= sec 0))
      (vbmp3-seek sec)
    (let ((total-sec (get '*vbmp3-input-info* 'time)))
      (if (>= (- sec) total-sec)
	  (vbmp3-seek 0)
	(vbmp3-seek (+ sec total-sec))))))

(defun vbmp3-mode-forward (&aux (sec (%vbmp3-mode-current-sec)))
  (interactive)
  (vbmp3-mode-seek (1+ sec)))

(defun vbmp3-mode-back (&aux (sec (%vbmp3-mode-current-sec)))
  (interactive)
  (vbmp3-mode-seek (1- sec)))

(defun vbmp3-mode-repeat-toggle ()
  (interactive)
  (setq *vbmp3-mode-repeat-active* (not *vbmp3-mode-repeat-active*))
  (if *vbmp3-mode-repeat-active*
      (progn
	(%vbmp3-mode-disable-shuffle)
	(start-timer +vbmp3-mode-repeat-interval+ 'vbmp3-mode-play))
    (stop-timer 'vbmp3-mode-play)))

(defun vbmp3-mode-shuffle-toggle ()
  (interactive)
  (setq *vbmp3-mode-shuffle-active* (not *vbmp3-mode-shuffle-active*))
  (if *vbmp3-mode-shuffle-active*
      (progn
	(%vbmp3-mode-disable-repeat)
	(start-timer +vbmp3-mode-shuffle-interval+ '%vbmp3-mode-shuffle))
    (stop-timer '%vbmp3-mode-shuffle)))

(defun vbmp3-mode-set-volume (left right)
  (interactive "nVolume size(L): \nnVolume size(R): ")
  (vbmp3-set-soft-volume left right)
  (vbmp3-reload)
  (multiple-value-bind (L R)
      (vbmp3-get-soft-volume)
    (setq *vbmp3-mode-current-volume-left*  L
	  *vbmp3-mode-current-volume-right* R
	  *vbmp3-mode-current-mode-line*    (%vbmp3-mode-get-mode-line-format))
    (%vbmp3-mode-line-update)))

(defun vbmp3-mode-set-equalizer (60Hz 170Hz 310Hz 600Hz 1KHz 3KHz 6KHz 12KHz 14KHz 16KHz &optional (type nil))
  (interactive "n60Hz (-120[-12dB] ～ 120[+12dB]): \nn170Hz (-120[-12dB] ～ 120[+12dB]): \nn310Hz (-120[-12dB] ～ 120[+12dB]): \nn600Hz (-120[-12dB] ～ 120[+12dB]): \nn1KHz (-120[-12dB] ～ 120[+12dB]): \nn3KHz (-120[-12dB] ～ 120[+12dB]): \nn6KHz (-120[-12dB] ～ 120[+12dB]): \nn12KHz (-120[-12dB] ～ 120[+12dB]): \nn14KHz (-120[-12dB] ～ 120[+12dB]): \nn16KHz (-120[-12dB] ～ 120[+12dB]): ")
  (vbmp3-set-equalizer 60Hz 170Hz 310Hz 600Hz 1KHz 3KHz 6KHz 12KHz 14KHz 16KHz)
  (vbmp3-reload)
  (setq *vbmp3-mode-current-sound-type* (if type type "UNKNOWN")
	*vbmp3-mode-current-mode-line*  (%vbmp3-mode-get-mode-line-format))
  (%vbmp3-mode-line-update))

(defun vbmp3-mode-set-id3-v1.1 (pathname artist track album year track-no genre genre-name comment)
  (interactive (let (num (pathname (vbmp3-playlist-current-line-pathname)))
		 (loop for (ind . val) in (read-from-string (format nil "(~{(:~A . ~S)~})" (vbmp3-mode-get-file-info pathname)))
		       do (setf (get 'vbmp3-tmp-file-info ind) val))
		 (list (read-file-name                          "File: "       :default pathname)
		       (read-string                             "Artist: "     :default (get 'vbmp3-tmp-file-info :artist))
		       (read-string                             "Track: "      :default (get 'vbmp3-tmp-file-info :track))
		       (read-string                             "Album: "      :default (get 'vbmp3-tmp-file-info :album))
		       (read-string                             "Year: "       :default (get 'vbmp3-tmp-file-info :year))
		       (read-from-string (read-string           "Track No: "   :default (write-to-string (get 'vbmp3-tmp-file-info :track-no))) nil)
		       (setq num (read-from-string (read-string "Genre: "      :default (write-to-string (get 'vbmp3-tmp-file-info :genre))) nil))
		       (read-string                             "Genre Name: " :default (vbmp3-get-genre num))
		       (read-string                             "Comment: "    :default (get 'vbmp3-tmp-file-info :comment)))))
  (if (vbmp3-set-tag-info-ex pathname
			     :artist     artist
			     :track      track
			     :album      album
			     :year       year
			     :comment    comment
			     :genre-name genre-name
			     :genre      genre
			     :track-no   track-no)
      (progn
	(%vbmp3-mode-reload-file-info)
	(vbmp3-db-update-playlist pathname)
	(%vbmp3-board-left-press *vbmp3-board-current-selected-line-number*)
	(%vbmp3-mode-reload-current-file-type)
	(vbmp3-info-insert-left-info)
	(vbmp3-board-insert)
	(message "done"))
    (%vbmp3-mode-error "ID3 タグの変更ができません")))

(defun vbmp3-mode-popup-pre-set-equalizer ()
  (interactive)
  (popup-list (loop for (x . y) in *vbmp3-mode-pre-set-equalizer-list* collect x)
	      #'(lambda (mode)
		  (multiple-value-call #'vbmp3-mode-set-equalizer
		    (funcall (cdr (assoc mode *vbmp3-mode-pre-set-equalizer-list* :test #'equal)))
		    mode))))

(defun vbmp3-mode-help ()
  (interactive)
  (popup-string +vbmp3-mode-usage+ (point)))

(defun vbmp3-mode-quit ()
  (interactive)
  (when (find-buffer +vbmp3-mode-playlist-buffer+)
    (delete-buffer +vbmp3-mode-playlist-buffer+))
  (when (find-buffer +vbmp3-mode-board-buffer+) 
    (delete-buffer +vbmp3-mode-board-buffer+))
  (when (find-buffer +vbmp3-mode-info-left-buffer+)
    (delete-buffer +vbmp3-mode-info-left-buffer+))
  (when (find-buffer +vbmp3-mode-info-right-buffer+)
    (delete-buffer +vbmp3-mode-info-right-buffer+))
  (awhen (find-pseudo-frame +vbmp3-mode-pseudo-frame-name+)
    (delete-pseudo-frame it))
  (%vbmp3-mode-reset-env)
  (vbmp3-free)
  (delete-other-windows))

(defun vbmp3-mode-get-file-info (pathname)
  (multiple-value-bind (tag-info mpeg-info)
      (vbmp3-get-file-info pathname)
    (unless (or (null tag-info) (null mpeg-info))
      (list :track       (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szTrackName))
	    :artist      (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szArtistName))
	    :album       (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szAlbumName))
	    :year        (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szYear))
	    :comment     (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szComment))
	    :genre-name  (si:unpack-string       tag-info (c:c-struct-offset-of TAG_INFO_11 vbmp3::szGenreName))
	    :genre       (TAG_INFO_11-genre      tag-info)
	    :track-no    (TAG_INFO_11-trackNo    tag-info)
	    :version     (MPEG_INFO-version      mpeg-info)
	    :layer       (MPEG_INFO-layer        mpeg-info)
	    :crc-disable (MPEG_INFO-crcDisable   mpeg-info)
	    :extension   (MPEG_INFO-extension    mpeg-info)
	    :mode        (MPEG_INFO-mode         mpeg-info)
	    :copyright   (MPEG_INFO-copyright    mpeg-info)
	    :original    (MPEG_INFO-original     mpeg-info)
	    :emphasis    (MPEG_INFO-emphasis     mpeg-info)
	    :channels    (MPEG_INFO-channels     mpeg-info)
	    :bit         (MPEG_INFO-bitrate      mpeg-info)
	    :sampling    (MPEG_INFO-samplingRate mpeg-info)
	    :file-size   (MPEG_INFO-fileSize     mpeg-info)
	    :frames      (MPEG_INFO-frames       mpeg-info)
	    :time        (MPEG_INFO-totalSec     mpeg-info)))))
