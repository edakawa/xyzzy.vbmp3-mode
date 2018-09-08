;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-info.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-info --- MP3 File Information and ID3 Tag Operation for vbmp3-mode

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Code:

(provide "vbmp3/vbmp3-info")

(defun vbmp3-info-startup ()
  (vbmp3-info-left-startup)
  (vbmp3-info-right-startup))

;;; Variable

(defconstant +vbmp3-mode-info-left-buffer+  "*vbmp3-info-left*")
(defconstant +vbmp3-mode-info-right-buffer+ "*vbmp3-info-right*")

(defvar *vbmp3-info-genre-name-list* '("Blues" "Classic Rock" "Country" "Dance" "Disco" "Funk" "Grunge" "Hip-Hop" "Jazz" "Metal" "New Age" "Oldies" "Other" "Pop" "R&B" "Rap" "Reggae" "Rock" "Techno" "Industrial" "Alternative" "Ska" "Death Metal" "Pranks" "Soundtrack" "Euro-tecno" "Ambient" "Trip-Hop" "Vocal" "Juzz+Funk" "Fusion" "Trance" "Classical" "Instrumental" "Acid" "House" "Game" "Sound Clip" "Gospel" "Noise" "AlternRock" "Bass" "Soul" "Punk" "Space" "Meditative" "Instrumental Pop" "Instrumental Rock" "Ethnic" "Gothic" "Darkwave" "Techno-Industrial" "Electronic" "Pop-Folk" "Eurodance" "Dream" "Southern Rock" "Comedy" "Cult" "Gangsta" "Top 40" "Christian Rap" "Pop/Funk" "Jungle" "Native American" "Cabaret" "New Wave" "Psychadelic" "Rave" "Showtunes" "Trailer" "Lo-Fi" "Tribal" "Acid Punk" "Acid Jazz" "Polka" "Retro" "Musical" "Rock & Roll" "Hard Rock" "Folk" "Folk/Rock" "National Folk" "Swing" "Fast-Fusion" "Bedob" "Latin" "Revival" "Celtic" "Bluegrass" "Avantagarde" "Gothic Rock" "Progressive Rock" "Psychadelic Rock" "Symphonic Rock" "Slow Rock" "Big band" "Chorus" "Easy Listening" "Acoustic" "Humour" "SpeechChanson" "Chanson" "Opera" "Chamber Music" "Sonata" "Symphony" "Booty Bass" "Primus" "Porn Groove" "Satire" "Slow Jam" "Club" "Tango" "Samba" "Folklore" "Ballad" "Power Ballad" "Rhytmic Soul" "Freestyle" "Duet" "Punk Rock" "Drum Solo" "Acapella" "Euro-House" "Dance Hall" "Goa" "Dram & Bass" "Club-House" "Hardcore" "Terror" "Indie" "BritPop" "Negerpunk" "Polsk Punk" "Beat" "Chiristian Gangsta Rap" "Heavy Metal" "Black Metal" "Crossover" "Contemporary Christian" "Christian Rock" "Merengue" "Salsa" "Thrash Metal" "Anime" "JPop" "Synthpop" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "" "Seiyu(J)" "Tecno Ambient(J)" "Moemoe(J)" "Tokusatsu(J)" "Anime(J)"))
(defvar *vbmp3-info-left-popup-menu* (define-popup-menu
				       (:item nil "ID3v1 タグ保存"
					'%vbmp3-info-left-set-id3-v1.1
					#'(lambda ()
					    (let ((ls `(,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-riff-wave+))
							,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-riff-mp3+))
							,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-id3-v2+))
							,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-mac-header+))
							,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-lyrics3-v2.00+))
							,(zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-standard-wave+)))))
					      (when (notevery #'(lambda (bool) (eq bool t)) ls)
						:disable))))
				       (:item nil "ID3v2 タグ除去"
					'%vbmp3-info-cut-id3-v2
					#'(lambda ()
					    (when (zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-id3-v2+))
					      :disable)))))


;;; Utility Function

(defun %vbmp3-info-error (msg)
  (message-box msg "ERROR VBMP3-INFO" '(:ok :exclamation))
  nil)

(defun %vbmp3-info-cut-id3-v2 ()
  (interactive)
  (when (yes-or-no-p "本当に除去しますか?")
    (message "Cuting ID3v2 Tag...")
    (if (vbmp3-cut-id3-v2 *vbmp3-mode-last-open-pathname*)
	(progn
	  (%vbmp3-mode-reload-current-file-type)
	  (vbmp3-info-insert-left-info)
	  (message "done"))
      (progn
	(%vbmp3-info-error "ID3 タグ v2 除去に失敗しました")
	(message "failure")))))

(defun %vbmp3-info-left-set-id3-v1.1 ()
  (interactive)
  (flet ((field-content (linenum)
	   (goto-line linenum)
	   (substitute-string (buffer-substring (progn (goto-bol) (point))
						(progn (goto-eol) (point)))
			      "^.*:[ \t　]+\\(.*\\)$"
			      "\\1")))
    (save-excursion
      (unless (minibuffer-window-p (selected-window))
	(let ((last-selected-buffer (selected-buffer)))
	  (switch-to-buffer +vbmp3-mode-info-left-buffer+)
	  (unwind-protect
	      (let ((artist   (field-content 1))
		    (track    (field-content 2))
		    (album    (field-content 3))
		    (track-no (field-content 4))
		    (genre    (field-content 5))
		    (year     (field-content 6))
		    (comment  (field-content 7)))
		(let ((genre-no (position genre *vbmp3-info-genre-name-list* :test #'equal)))
		  (vbmp3-mode-set-id3-v1.1 *vbmp3-mode-last-open-pathname*
					   artist
					   track
					   album
					   year
					   (if (string-match "^[ \t　]*[0-9]+[ \t　]*$" track-no) (read-from-string track-no) track-no)
					   (or                      genre-no "Anime(J)")
					   (or                      genre-no -1)
					   comment)))
	    (switch-to-buffer last-selected-buffer)))))))


;;; Interface Function

(defun vbmp3-info-left-startup ()
  (switch-to-buffer +vbmp3-mode-info-left-buffer+)
  (kill-all-local-variables)
  (make-local-variable 'need-not-save)
  (setq need-not-save t)
  (make-local-variable 'auto-save)
  (setq auto-save nil)
  (make-local-variable 'mode-line-format)
  (setq mode-line-format "")
  (set-local-window-flags (selected-buffer) *window-flag-vscroll-bar* nil)
  (set-local-window-flags (selected-buffer) *window-flag-hscroll-bar* nil)
  (defvar-local *vbmp3-info-left-map* nil)
  (unless *vbmp3-info-left-map*
    (setq *vbmp3-info-left-map* (make-sparse-keymap))
    (define-key *vbmp3-info-left-map* #\RBtnUp 'vbmp3-mode-right-press))
  (use-keymap *vbmp3-info-left-map*)
  (split-window-vertically)
  (other-window))

(defun vbmp3-info-right-startup ()
  (switch-to-buffer +vbmp3-mode-info-right-buffer+)
  (kill-all-local-variables)
  (make-local-variable 'need-not-save)
  (setq need-not-save t)
  (make-local-variable 'auto-save)
  (setq auto-save nil)
  (make-local-variable 'mode-line-format)
  (setq mode-line-format "")
  (set-local-window-flags (selected-buffer) *window-flag-vscroll-bar* nil)
  (set-local-window-flags (selected-buffer) *window-flag-hscroll-bar* nil)
  (set-window (get-buffer-window (find-buffer "*vbmp3-board*"))))

(defun vbmp3-info-update-right-mode-line ()
  (unless (minibuffer-window-p (selected-window))
    (let ((last-selected-buffer (selected-buffer)))
      (switch-to-buffer +vbmp3-mode-info-right-buffer+)
      (unwind-protect
	  (multiple-value-bind (id count)
	      (vbmp3-db-select-id-and-count-play-from-t-playlist *vbmp3-mode-last-open-directory*
								 *vbmp3-mode-last-open-file-name*)
	    (when (and id count)
	      (vbmp3-db-update-t-playlist-set-count-play id)
	      (setq mode-line-format (format nil "-*- Plays: ~A -*-" (1+ count)))
	      (update-mode-line)))
	(switch-to-buffer last-selected-buffer)))))

(defun vbmp3-info-insert-right-info ()
  (unless (minibuffer-window-p (selected-window))
    (let ((last-selected-buffer (selected-buffer)))
      (switch-to-buffer +vbmp3-mode-info-right-buffer+)
      (delete-region (point-min) (point-max))
      (insert (format nil
		      "Bit Rate     : ~A kbps~%Sampling Rate: ~A kHz~%~%~%File Name    : ~A~%File Size    : ~4F MB~%Last Modified: ~A"
		      (get *vbmp3-mode-file-info* :bit)
		      (/ (or (get *vbmp3-mode-file-info* :sampling) 0) 1000.0)
		      *vbmp3-mode-last-open-file-name*
		      (/ (file-length *vbmp3-mode-last-open-pathname*) (* 1024 1024))
		      (format-date-string "%Y-%m-%d %H:%M:%S" (file-write-time *vbmp3-mode-last-open-pathname*))))
      (setq mode-line-format "-*- Plays: -*-")
      (goto-line 1)
      (update-mode-line)
      (switch-to-buffer last-selected-buffer))))

(defun vbmp3-info-insert-left-info ()
  (unless (minibuffer-window-p (selected-window))
    (let ((last-selected-buffer (selected-buffer)))
      (switch-to-buffer +vbmp3-mode-info-left-buffer+)
      (delete-region (point-min) (point-max))
      (insert (format nil
		      "Artist  : ~A~%Track   : ~A~%Album   : ~A~%Track No: ~A~%Genre   : ~A~%Year    : ~A~%Comment : ~A"
		      (get *vbmp3-mode-file-info* :artist)
		      (get *vbmp3-mode-file-info* :track)
		      (get *vbmp3-mode-file-info* :album)
		      (if (> 0 (get *vbmp3-mode-file-info* :track-no)) "-1" (get *vbmp3-mode-file-info* :track-no))
		      (get *vbmp3-mode-file-info* :genre-name)
		      (get *vbmp3-mode-file-info* :year)
		      (get *vbmp3-mode-file-info* :comment)))
      (setq mode-line-format (format nil
				     "-*- ID3 Tag: ~A -*-"
				     (cond ((not (zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-id3-v2+))) "v2")
					   ((not (zerop (logand *vbmp3-mode-current-file-type* +vbmp3-file-type-id3-v1+))) "v1")
					   (t                                                                              "NONE"))))
      (goto-line 1)
      (switch-to-buffer last-selected-buffer)
      (update-mode-line))))
