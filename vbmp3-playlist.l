;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-playlist.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-playlist --- Playlist for vbmp3-mode

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Code:

(provide "vbmp3/vbmp3-playlist")

(defun vbmp3-playlist-startup ()
  (switch-to-buffer +vbmp3-mode-playlist-buffer+)
  (kill-all-local-variables)
  (setq buffer-mode 'vbmp3-mode)
  (setq mode-name "♪")
  (use-keymap *vbmp3-mode-map*)
  (make-local-variable 'need-not-save)
  (setq need-not-save t)
  (make-local-variable 'auto-save)
  (setq auto-save nil)
  (make-local-variable 'mode-line-format)
  (setq mode-line-format "vbmp3 [00:00:00]")
  (set-local-window-flags (selected-buffer) *window-flag-cursor-line* t)
  (set-local-window-flags (selected-buffer) *window-flag-hscroll-bar* nil)
  (vbmp3-db-startup)
  (unless buffer-read-only
    (toggle-read-only))
  (split-window-vertically (floor (/ (window-width) 4.5))))

;;; Variable

(defconstant +vbmp3-mode-playlist-buffer+ "*vbmp3-playlist*")

(defvar *vbmp3-mode-playlist*          nil)
(defvar *vbmp3-mode-playlist-pathname* (merge-pathnames "site-lisp/vbmp3/playlist_history.l" (si:system-root)))
(defvar *vbmp3-playlist-popup-menu*    (define-popup-menu
					 (:popup nil "mp3 追加"
					  (:item nil "フォルダ選択" 'vbmp3-db-query-add-playlist-from-directory-name-dialog)
					  (:item nil "ファイル選択" 'vbmp3-db-query-add-playlist-from-file-name-dialog))
					 :sep
					 (:item nil "再生"     'vbmp3-mode-playlist-play  #'(lambda () (when   (or (%vbmp3-mode-playing-p) (%vbmp3-mode-pause-p)) :disable)))
					 (:item nil "停止"     'vbmp3-mode-stop           #'(lambda () (when   (or (%vbmp3-mode-stop-p)    (%vbmp3-mode-pause-p)) :disable)))
					 (:item nil "一時停止" 'vbmp3-mode-pause          #'(lambda () (unless (%vbmp3-mode-playing-p)                            :disable)))
					 (:item nil "再開"     'vbmp3-mode-restart        #'(lambda () (unless (%vbmp3-mode-pause-p)                              :disable)))
					 :sep
					 (:popup nil "イコライザ"
					  (:item nil "Normal"       '%vbmp3-mode-set-equalizer-normal       #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Normal")       :check)))
					  (:item nil "Rock"         '%vbmp3-mode-set-equalizer-rock         #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Rock")         :check)))
					  (:item nil "Pop"          '%vbmp3-mode-set-equalizer-pop          #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Pop")          :check)))
					  (:item nil "Classic"      '%vbmp3-mode-set-equalizer-classic      #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Classic")      :check)))
					  (:item nil "Live"         '%vbmp3-mode-set-equalizer-live         #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Live")         :check)))
					  (:item nil "Base Boost"   '%vbmp3-mode-set-equalizer-base-boost   #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Base Boost")   :check)))
					  (:item nil "Treble Boost" '%vbmp3-mode-set-equalizer-treble-boost #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Treble Boost") :check)))
					  (:item nil "Total Boost"  '%vbmp3-mode-set-equalizer-total-boost  #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Total Boost")  :check)))
					  (:item nil "Total Reduce" '%vbmp3-mode-set-equalizer-total-reduce #'(lambda () (when (string= *vbmp3-mode-current-sound-type* "Total Reduce") :check))))
					 :sep
					 (:item nil "前の曲" 'vbmp3-mode-prev)
					 (:item nil "次の曲" 'vbmp3-mode-next)
					 :sep
					 (:popup nil "ボリューム"
					  (:item nil "20 上げる" '%vbmp3-mode-up-volume-by-20)
					  (:item nil "20 下げる" '%vbmp3-mode-down-volume-by-20)
					  (:item nil "最大にする"  '%vbmp3-mode-max-volume)
					  (:item nil "最小にする"  '%vbmp3-mode-min-volume))
					 :sep
					 (:popup nil "再生速度"
					  (:item nil "標準にする" '%vbmp3-mode-reset-pitch)
					  (:item nil "20% 上げる" '%vbmp3-mode-up-pitch-by-0.2)
					  (:item nil "20% 下げる" '%vbmp3-mode-down-pitch-by-0.2)
					  (:item nil "最大にする" '%vbmp3-mode-max-pitch)
					  (:item nil "最小にする" '%vbmp3-mode-min-pitch))
					 :sep
					 (:item nil "リピートモード"   'vbmp3-mode-repeat-toggle  #'(lambda () (when *vbmp3-mode-repeat-active*  :check)))
					 (:item nil "シャッフルモード" 'vbmp3-mode-shuffle-toggle #'(lambda () (when *vbmp3-mode-shuffle-active* :check)))
					 :sep
					 (:popup nil "並び替え"
					  (:item nil "アーティスト名" 'vbmp3-playlist-sort-artist)
					  (:item nil "トラック名"     'vbmp3-playlist-sort-track)
					  (:item nil "演奏時間"       'vbmp3-playlist-sort-time)
					  (:item nil "ファイル名"     'vbmp3-playlist-sort-file))
					 :sep
					 (:item nil "終了" 'vbmp3-mode-quit)))


;;; Macro

(defmacro aif (test-form then-form &optional else-form)
  `(let ((it ,test-form))
     (if it ,then-form ,else-form)))

(defmacro awhen (test-form &body body)
  `(aif ,test-form
       (progn ,@body)))


;;; Interface Function

(defun vbmp3-playlist-make-input-info-tag (pathname artist track bit sampling time)
  (list :pathname pathname :artist artist :track track :bit bit :sampling sampling :time time))

(defun vbmp3-playlist-add-playlist (mp3-tag-info)
  (unless (member (getf mp3-tag-info :pathname)
		  (vbmp3-playlist-select-from-playlist :pathname)
		  :test #'string-equal)
    (push mp3-tag-info *vbmp3-mode-playlist*)))

(defun vbmp3-playlist-delete-current-line ()
  (interactive)
  (awhen (vbmp3-playlist-current-line-pathname)
    (when (yes-or-no-p (format nil "~A をプレイリストから削除しますか?" (file-namestring it)))
      (setq *vbmp3-mode-playlist* (remove-if #'(lambda (ls) (string-equal (getf ls :pathname) it)) *vbmp3-mode-playlist*))
      (vbmp3-playlist-reload-playlist))))

(defun vbmp3-playlist-sort-artist ()
  (interactive)
  (long-operation
    (setq *vbmp3-mode-playlist* (sort *vbmp3-mode-playlist* #'string< :key #'(lambda (ls) (getf ls :artist))))
    (vbmp3-playlist-reload-playlist)))

(defun vbmp3-playlist-sort-track ()
  (interactive)
  (long-operation
    (setq *vbmp3-mode-playlist* (sort *vbmp3-mode-playlist* #'string< :key #'(lambda (ls) (getf ls :track))))
    (vbmp3-playlist-reload-playlist)))

(defun vbmp3-playlist-sort-time ()
  (interactive)
  (long-operation
    (setq *vbmp3-mode-playlist* (sort *vbmp3-mode-playlist* #'< :key #'(lambda (ls) (getf ls :time))))
    (vbmp3-playlist-reload-playlist)))

(defun vbmp3-playlist-sort-file ()
  (interactive)
  (long-operation
    (setq *vbmp3-mode-playlist* (sort *vbmp3-mode-playlist* #'string< :key #'(lambda (ls) (getf ls :pathname))))
    (vbmp3-playlist-reload-playlist)))

(defun vbmp3-playlist-save-playlist ()
  (long-operation
    (with-open-file (out *vbmp3-mode-playlist-pathname* :direction :output :if-exists :overwrite :if-does-not-exist :create)
      (print *vbmp3-mode-playlist* out))))

(defun vbmp3-playlist-load-playlist ()
  (long-operation
    (with-open-file (in *vbmp3-mode-playlist-pathname* :direction :input :if-does-not-exist :create)
      (setf *vbmp3-mode-playlist* (read in nil)))))

(defun vbmp3-playlist-change-total-sec-to-time (sec)
  (let ((minute (mod (floor (/ sec 60)) 60))
	(second (mod sec 60)))
    (format nil "~2,'0D:~2,'0D" minute second)))

(defun vbmp3-playlist-select-from-playlist (column)
  (mapcar #'(lambda (record) (getf record column)) *vbmp3-mode-playlist*))

(defun vbmp3-playlist-reload-playlist (&key update)
  ;;; update 削除予定
  (when update
    (long-operation
      (let ((pathname-ls (reverse (vbmp3-playlist-select-from-playlist :pathname)))
	    (playlist *vbmp3-mode-playlist*))
	(setq *vbmp3-mode-playlist* nil)
	(dolist (pathname pathname-ls)
	  (aif (vbmp3-mode-get-file-info pathname)
	      (vbmp3-playlist-add-playlist (vbmp3-playlist-make-input-info-tag pathname
									       (getf it :artist)
									       (getf it :track)
									       (getf it :bit)
									       (getf it :sampling)
									       (getf it :time)))
	    (let ((tmp (find-if #'(lambda (ls) (string-equal pathname (getf ls :pathname))) playlist)))
	      (when tmp
		(vbmp3-playlist-add-playlist (vbmp3-playlist-make-input-info-tag pathname
										 (getf tmp :artist)
										 (getf tmp :track)
										 (getf tmp :bit)
										 (getf tmp :sampling)
										 (getf tmp :time))))))))))
  (let ((n (current-line-number)))
    (vbmp3-playlist-save-playlist)
    (vbmp3-playlist-insert-playlist)
    (goto-line n)))

(defun vbmp3-playlist-insert-playlist (&optional (question t))
  (when *vbmp3-mode-playlist*
    (switch-to-buffer +vbmp3-mode-playlist-buffer+)
    (when buffer-read-only
      (toggle-read-only))
    (delete-region (point-min) (point-max))
    (let ((max-artist-column (loop for artist in (vbmp3-playlist-select-from-playlist :artist) maximize (count-column artist)))
	  (max-track-column (loop for track in (vbmp3-playlist-select-from-playlist :track) maximize (count-column track))))
      (let* ((artist-column (if (> max-artist-column 6) (+ max-artist-column 4) (+ 6 4)))
	     (track-column  (+ artist-column (if (> max-track-column  5) (+ max-track-column  4) (+ 5 4))))
	     (time-column   (+ track-column 9))
	     (file-column   (+ time-column)))
	(insert (format nil "~A~VT~A~VT~A~VT~A~VT~%~A~VT~A~VT~A~VT~A~VT"
			"Artist" artist-column
			"Track"  track-column
			"Time"   time-column
			"File"   file-column
			"------" artist-column
			"-----"  track-column
			"----"   time-column
			"----"   file-column))
	(dolist (r *vbmp3-mode-playlist*)
	  (let ((time (vbmp3-playlist-change-total-sec-to-time (getf r :time))))
	    (insert (format nil "~%~A~VT~A~VT~A~VT~A~VT"
			    (getf r :artist)   artist-column
			    (getf r :track)    track-column
			    time               time-column
			    (getf r :pathname) (1- file-column)))))))
    (unless buffer-read-only
      (toggle-read-only))
    (goto-line 3)))

(defun vbmp3-playlist-current-line-pathname ()
  (save-excursion
    (string-match "[a-zA-Z]:/.*\\.mp3"
		  (buffer-substring (progn (goto-bol) (point))
				    (progn (goto-eol) (point))))
    (match-string 0)))
