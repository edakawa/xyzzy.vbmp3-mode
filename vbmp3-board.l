;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-board.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-board --- MP3 file selection interface for vbmp3-mode

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Code:

(provide "vbmp3/vbmp3-board")

(defun vbmp3-board-startup ()
  (switch-to-buffer +vbmp3-mode-board-buffer+)
  (kill-all-local-variables)
  (make-local-variable 'need-not-save)
  (setq need-not-save t)
  (make-local-variable 'auto-save)
  (setq auto-save nil)
  (make-local-variable 'mode-line-format)
  (setq mode-line-format "-*- Mode: -*-")
  (setq buffer-mode 'vbmp3-board)
  (set-local-window-flags (selected-buffer) *window-flag-hscroll-bar* nil)
  (set-local-window-flags (selected-buffer) *window-flag-cursor-line* t)
  (defvar-local *vbmp3-board-map* nil)
  (unless *vbmp3-board-map*
    (setq *vbmp3-board-map* (make-sparse-keymap))
    (define-key *vbmp3-board-map* #\RET    '%vbmp3-board-enter-press)
    (define-key *vbmp3-board-map* #\LBtnUp 'vbmp3-mode-left-press)
    (define-key *vbmp3-board-map* #\RBtnUp 'vbmp3-mode-right-press))
  (use-keymap *vbmp3-board-map*)
  (other-window)
  (split-window -8))


;;; Variable

(defconstant +vbmp3-mode-board-buffer+ "*vbmp3-board*")

(defvar *vbmp3-board-current-selected-line-number* nil)

(defvar *vbmp3-board-popup-menu* (define-popup-menu
				   (:item nil "アーティスト" 'vbmp3-board-change-artist #'(lambda () (when (eq *vbmp3-mode-board-type* 'artist) :check)))
				   (:item nil "アルバム"     'vbmp3-board-change-album  #'(lambda () (when (eq *vbmp3-mode-board-type* 'album)  :check)))
				   (:item nil "ジャンル"     'vbmp3-board-change-genre  #'(lambda () (when (eq *vbmp3-mode-board-type* 'genre)  :check)))
				   (:item nil "年代"         'vbmp3-board-change-year   #'(lambda () (when (eq *vbmp3-mode-board-type* 'year)   :check)))))


;;; Utility Function

(defun %vbmp3-board-error (msg)
  (message-box msg "ERROR VBMP3-BOARD" '(:ok :exclamation)))

(defun %vbmp3-board-enter-press ()
  (interactive)
  (%vbmp3-board-left-press (current-line-number)))

(defun %vbmp3-board-left-press (&optional (clinenum (current-line-number)))
  (flet ((invalid-line-p () (or (null clinenum) (= 2 clinenum))))
    (let ((last-selected-buffer (selected-buffer)))
      (switch-to-buffer +vbmp3-mode-board-buffer+)
      (unwind-protect
	  (unless (invalid-line-p)
	    (save-excursion
	      (goto-line clinenum)
	      (setq *vbmp3-board-current-selected-line-number* clinenum)
	      (let ((name (substitute-string (buffer-substring (progn (goto-bol) (point))
							       (progn (goto-eol) (point)))
					     "^\([ ]*[0-9]+\) \\(.*\\)$"
					     "\\1")))
		(setq *vbmp3-mode-playlist*
		      (if (= 1 clinenum)
			  (vbmp3-db-gen-playlist 'artist)
			(vbmp3-db-gen-playlist *vbmp3-mode-board-type* name)))))
	    (vbmp3-playlist-insert-playlist)
	    (vbmp3-playlist-save-playlist))
	(switch-to-buffer last-selected-buffer)))))


;;; Interface Function

(defun vbmp3-board-insert ()
  (let ((last-selected-buffer (selected-buffer)))
    (switch-to-buffer +vbmp3-mode-board-buffer+)
    (let ((mode (case *vbmp3-mode-board-type*
		  (artist (cons 'artist "ARTIST"))
		  (album  (cons 'album  "ALBUM"))
		  (genre  (cons 'genre  "GENRE"))
		  (year   (cons 'year   "YEAR"))
		  (t (%vbmp3-board-error "*vbmp3-mode-board-type* の値が不正です")
		     (return-from vbmp3-board-insert)))))
      (setq mode-line-format (format nil "-*- Mode: ~A -*-" (cdr mode)))
      (unwind-protect
	  (progn
	    (when buffer-read-only
	      (toggle-read-only))
	    (delete-region (point-min) (point-max))
	    (let* ((num (write-to-string (vbmp3-db-count-table 'artist)))
		   (siz (count-column num)))
	      (insert (format nil
			      (format nil "(~~~DA) ALL~%" siz)
			      num))
	      (loop for (id . name) in (vbmp3-db-get-name-list-from-m-table (car mode))
		    do (insert (format nil
				       (format nil "~%(~~~DD) ~A" siz name)
				       (vbmp3-db-count-id (car mode) id))))
	      (goto-line 3)))
	(progn
	  (unless buffer-read-only
	    (toggle-read-only))
	  (switch-to-buffer last-selected-buffer))))))

(defun vbmp3-board-change-type (where)
  (setq *vbmp3-mode-board-type* (case where
				  (artist 'artist)
				  (album  'album)
				  (genre  'genre)
				  (year   'year)
				  (t (return-from vbmp3-board-change-type nil)))))

(defun vbmp3-board-change-artist ()
  (interactive)
  (vbmp3-board-change-type 'artist)
  (vbmp3-board-insert))

(defun vbmp3-board-change-album ()
  (interactive)
  (vbmp3-board-change-type 'album)
  (vbmp3-board-insert))

(defun vbmp3-board-change-genre ()
  (interactive)
  (vbmp3-board-change-type 'genre)
  (vbmp3-board-insert))

(defun vbmp3-board-change-year ()
  (interactive)
  (vbmp3-board-change-type 'year)
  (vbmp3-board-insert))
