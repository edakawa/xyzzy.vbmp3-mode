;;; -*- Mode: Lisp -*-

;;; $Id: vbmp3-db.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-db --- SQLite ODBC module for vbmp3-mode

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Code:

(provide "vbmp3/vbmp3-db")

(defun vbmp3-db-startup ()
  (handler-case
      (progn
	(setq *vbmp3-db-conn* (ole-create-object "ADODB.Connection"))
	(ole-method *vbmp3-db-conn* 'Open (concat "driver=SQLite3 ODBC Driver;database=" *vbmp3-db-file*))
	(when (zerop (file-length *vbmp3-db-file*))
	  (message "Creating Database...")
	  (vbmp3-db-execute (concat "CREATE TABLE m_artist("
				    "    artist_id   INTEGER PRIMARY KEY,"
				    "    artist_name TEXT    UNIQUE);"
				    "CREATE INDEX m_artist_name_idx ON m_artist(artist_name);"

				    "CREATE TABLE m_album("
				    "    album_id   INTEGER PRIMARY KEY,"
				    "    album_name TEXT    UNIQUE);"
				    "CREATE INDEX m_album_name_idx ON m_album(album_name);"

				    "CREATE TABLE m_genre("
				    "    genre_id   INTEGER PRIMARY KEY,"
				    "    genre_name TEXT    UNIQUE);"
				    "CREATE INDEX m_genre_name_idx ON m_genre(genre_name);"

				    "CREATE TABLE m_path("
				    "    path_id   INTEGER PRIMARY KEY,"
				    "    path_name TEXT    UNIQUE);"
				    "CREATE INDEX m_path_name_idx ON m_path(path_name);"

				    "CREATE TABLE m_year("
				    "    year_id   INTEGER PRIMARY KEY,"
				    "    year_name TEXT    UNIQUE);"
				    "CREATE INDEX m_year_name_idx ON m_year(year_name);"

				    "CREATE TABLE t_playlist("
				    "    id         INTEGER PRIMARY KEY,"
				    "    count_play INTEGER DEFAULT 0,"
				    "    artist_id  INTEGER NOT NULL,"
				    "    track      TEXT    DEFAULT \"\","
				    "    album_id   INTEGER NOT NULL,"
				    "    genre_id   INTEGER NOT NULL,"
				    "    year_id    INTEGER NOT NULL,"
				    "    path_id    INTEGER NOT NULL,"
				    "    file       TEXT    NOT NULL,"
				    "    comment    TEXT    DEFAULT \"\","
				    "    time       INTEGER NOT NULL,"
				    "    UNIQUE(path_id, file));"
				    "CREATE INDEX t_playlist_id_idx        ON t_playlist(id);"
				    "CREATE INDEX t_playlist_artist_id_idx ON t_playlist(artist_id);"
				    "CREATE INDEX t_playlist_album_id_idx  ON t_playlist(album_id);"
				    "CREATE INDEX t_playlist_year_id_idx   ON t_playlist(year_id);"
				    "CREATE INDEX t_playlist_genre_id_idx  ON t_playlist(genre_id);"))
	  (message "Created ~A" *vbmp3-db-file*)))
      (error (c)
	(%vbmp3-db-error (concat "VBMP3-DB-STARTUP: データベースの作成に失敗しました: " (si:*condition-string c))))))


;;; Macro

(defmacro aif (test-form then-form &optional else-form)
  `(let ((it ,test-form))
     (if it ,then-form ,else-form)))

(defmacro awhen (test-form &body body)
  `(aif ,test-form
       (progn ,@body)))


;;; Variable

(defvar *vbmp3-db-conn* nil)
(defvar *vbmp3-db-file* (merge-pathnames "site-lisp/vbmp3/playlist.db" (si:system-root)))


;;; Utility Function

(defun %vbmp3-db-error (msg)
  (message-box msg "ERROR VBMP3-DB" '(:ok :exclamation)))

(defun %vbmp3-db-escape-string (str)
  (substitute-string str "'" "''"))

(defun %vbmp3-db-convert-null-string (value)
  (if (string-match "[^ \t　]" value)
      value
    "-*- 未設定 -*-"))


;;; Interface Function

(defun vbmp3-db-execute (query)
  (ole-method *vbmp3-db-conn* 'Execute query))


(defun vbmp3-db-select-id-and-count-play-from-t-playlist (path file)
  (awhen (vbmp3-db-select-id-from-m-table 'path (%vbmp3-db-escape-string path))
    (let ((rs (vbmp3-db-execute (format nil
					"SELECT id, count_play FROM t_playlist WHERE path_id = ~A AND file = '~A'"
					it
					(%vbmp3-db-escape-string file)))))
      (unless #{rs.EOF}
	(values #{rs.Fields[0].Value} #{rs.Fields[1].Value})))))

(defun vbmp3-db-update-t-playlist-set-count-play (id)
  (vbmp3-db-execute (format nil "UPDATE t_playlist SET count_play = count_play + 1 WHERE id = ~A" id)))

(defun vbmp3-db-delete-record (pathname)
  (let ((path (%vbmp3-db-escape-string (directory-namestring pathname)))
	(file (%vbmp3-db-escape-string (file-namestring      pathname))))
    (awhen (vbmp3-db-select-id-from-m-table 'path path)
      (message "Deleting... ~A" pathname)
      (when (vbmp3-db-execute (format nil "DELETE FROM t_playlist WHERE path_id = ~A AND file = '~A'" (write-to-string it) file))
	(message "done")))))

(defun vbmp3-db-get-name-list-from-m-table (where)
  (let ((rs (vbmp3-db-execute (case where
				(artist "SELECT artist_id, artist_name FROM m_artist ORDER BY artist_name")
				(album  "SELECT album_id,  album_name  FROM m_album  ORDER BY album_name")
				(genre  "SELECT genre_id,  genre_name  FROM m_genre  ORDER BY genre_name")
				(year   "SELECT year_id,   year_name   FROM m_year   ORDER BY year_name")
				(file   "SELECT m_path.path_name, t_playlist.file FROM t_playlist NATURAL JOIN m_path")
				(t      (return-from vbmp3-db-get-name-list-from-m-table))))))
    (let ((ret '()))
      (case where
	(file
	 (while (not #{rs.EOF})
	   (push (concat #{rs.Fields[0].Value} #{rs.Fields[1].Value}) ret)
	   (ole-method rs 'MoveNext))
	 (nreverse ret))
	(t
	 (while (not #{rs.EOF})
	   (push (cons #{rs.Fields[0].Value} #{rs.Fields[1].Value}) ret)
	   (ole-method rs 'MoveNext))
	 (nreverse ret))))))

(defun vbmp3-db-insert-or-ignore-m-name (where name &aux (escaped-name (%vbmp3-db-escape-string name)))
  (vbmp3-db-execute (case where
		      (artist (format nil "INSERT OR IGNORE INTO m_artist VALUES(NULL, '~A');" escaped-name))
		      (album  (format nil "INSERT OR IGNORE INTO m_album  VALUES(NULL, '~A');" escaped-name))
		      (genre  (format nil "INSERT OR IGNORE INTO m_genre  VALUES(NULL, '~A');" escaped-name))
		      (year   (format nil "INSERT OR IGNORE INTO m_year   VALUES(NULL, '~A');" escaped-name))
		      (path   (format nil "INSERT OR IGNORE INTO m_path   VALUES(NULL, '~A');" escaped-name))
		      (t      (return-from vbmp3-db-insert-or-ignore-m-name)))))

(defun vbmp3-db-select-id-from-m-table (where value &aux (escaped-value (%vbmp3-db-escape-string value)))
  (let ((rs (vbmp3-db-execute (case where
				(artist (format nil "SELECT artist_id FROM m_artist WHERE artist_name = '~A'" escaped-value))
				(album  (format nil "SELECT album_id  FROM m_album  WHERE album_name  = '~A'" escaped-value))
				(genre  (format nil "SELECT genre_id  FROM m_genre  WHERE genre_name  = '~A'" escaped-value))
				(year   (format nil "SELECT year_id   FROM m_year   WHERE year_name   = '~A'" escaped-value))
				(path   (format nil "SELECT path_id   FROM m_path   WHERE path_name   = '~A'" escaped-value))
				(t      (return-from vbmp3-db-select-id-from-m-table nil))))))
       (unless #{rs.EOF}
	 #{rs.Fields[0].Value})))

(defun vbmp3-db-insert-and-select-id-from-m-name (where name)
  (let ((str (%vbmp3-db-convert-null-string name)))
    (vbmp3-db-insert-or-ignore-m-name where str)
    (vbmp3-db-select-id-from-m-table  where str)))

(defun vbmp3-db-gen-playlist (where &optional (value nil))
  (let ((rs (vbmp3-db-execute (concat "SELECT m_path.path_name, t_playlist.file, m_artist.artist_name, t_playlist.track, t_playlist.time, t_playlist.id "
				      "FROM t_playlist "
				      "INNER JOIN m_path   ON t_playlist.path_id   = m_path.path_id "
				      "INNER JOIN m_artist ON t_playlist.artist_id = m_artist.artist_id "
				      (if value
					  (case where
					    (artist (format nil "WHERE t_playlist.artist_id = ~A" (vbmp3-db-select-id-from-m-table 'artist (%vbmp3-db-escape-string value))))
					    (album  (format nil "WHERE t_playlist.album_id  = ~A" (vbmp3-db-select-id-from-m-table 'album  (%vbmp3-db-escape-string value))))
					    (genre  (format nil "WHERE t_playlist.genre_id  = ~A" (vbmp3-db-select-id-from-m-table 'genre  (%vbmp3-db-escape-string value))))
					    (year   (format nil "WHERE t_playlist.year_id   = ~A" (vbmp3-db-select-id-from-m-table 'year   (%vbmp3-db-escape-string value)))))
					"")))))
    (let ((ret '()))
      (while (not #{rs.EOF})
	(let ((pathname (concat #{rs.Fields[0].Value} #{rs.Fields[1].Value})))
	  (push `(:pathname ,pathname
		  :artist   ,#{rs.Fields[2].Value}
		  :track    ,#{rs.Fields[3].Value}
		  :time     ,#{rs.Fields[4].Value})
		ret)
	  (ole-method rs 'MoveNext)))
      (nreverse ret))))

(defun vbmp3-db-count-table (where)
  (let ((rs (vbmp3-db-execute (format nil "SELECT COUNT(*) FROM ~A" (case where
								      (artist   't_playlist)
								      (album    'm_album)
								      (genre    'm_genre)
								      (year     'm_year)
								      (t (return-from vbmp3-db-count-table nil)))))))
    (unless #{rs.EOF}
      #{rs.Fields[0].Value})))

(defun vbmp3-db-count-id (where id)
  (let ((rs (vbmp3-db-execute (format nil "SELECT COUNT(*) FROM t_playlist WHERE ~A = ~A" (case where
											    (artist 'artist_id)
											    (album  'album_id)
											    (genre  'genre_id)
											    (year   'year_id)
											    (t (return-from vbmp3-db-count-id nil)))
											   id))))
    (unless #{rs.EOF}
      #{rs.Fields[0].Value})))

(defun vbmp3-db-add-playlist (pathname)
  (awhen (vbmp3-mode-get-file-info pathname)
    (message "Processing... ~A" pathname)
    (vbmp3-db-execute (format nil "INSERT OR IGNORE INTO t_playlist VALUES(NULL, 0, ~A, '~A', ~A, ~A, ~A, ~A, '~A', '~A', ~A);"
			      (vbmp3-db-insert-and-select-id-from-m-name 'artist (getf it :artist))
			      (%vbmp3-db-escape-string                    (%vbmp3-db-convert-null-string  (getf it :track)))
			      (vbmp3-db-insert-and-select-id-from-m-name 'album  (getf it :album))
			      (vbmp3-db-insert-and-select-id-from-m-name 'genre  (getf it :genre-name))
			      (vbmp3-db-insert-and-select-id-from-m-name 'year   (getf it :year))
			      (vbmp3-db-insert-and-select-id-from-m-name 'path   (directory-namestring pathname))
			      (%vbmp3-db-escape-string                    (file-namestring pathname))
			      (%vbmp3-db-escape-string                    (%vbmp3-db-convert-null-string (getf it :comment)))
			      (getf it :time)))
    (message "done")))

(defun vbmp3-db-update-playlist (pathname)
  (awhen (vbmp3-mode-get-file-info pathname)
    (message "Updating... ~A" pathname)
    (vbmp3-db-execute (format nil
			      "UPDATE t_playlist SET artist_id = ~A, track = '~A', album_id = ~A, genre_id = ~A, year_id = ~A, comment = '~A' WHERE path_id = ~A AND file = '~A'"
			      (vbmp3-db-insert-and-select-id-from-m-name 'artist (getf it :artist))
			      (%vbmp3-db-escape-string                   (%vbmp3-db-convert-null-string (getf it :track)))
			      (vbmp3-db-insert-and-select-id-from-m-name 'album  (getf it :album))
			      (vbmp3-db-insert-and-select-id-from-m-name 'genre  (getf it :genre-name))
			      (vbmp3-db-insert-and-select-id-from-m-name 'year   (getf it :year))
			      (%vbmp3-db-escape-string                   (%vbmp3-db-convert-null-string (getf it :comment)))
			      (vbmp3-db-insert-and-select-id-from-m-name 'path   (directory-namestring pathname))
			      (%vbmp3-db-escape-string                   (file-namestring pathname))))
    (message "done")))

(defun vbmp3-db-query-add-playlist-from-file-name-dialog ()
  (interactive)
  (aif (file-name-dialog :title "追加するファイルを選択" :filter '(("mp3 ファイル (*.mp3)" . "*.mp3")))
      (handler-case
	  (progn
	    (vbmp3-db-add-playlist it)
	    (%vbmp3-board-left-press *vbmp3-board-current-selected-line-number*)
	    (vbmp3-board-insert))
	(error (c)
	  (%vbmp3-db-error (format nil "VBMP3-DB-QUERY-ADD-PLAYLIST-FROM-FILE: ~A" (si:*condition-string c)))))))

(defun vbmp3-db-query-add-playlist-from-directory-name-dialog (&aux (count 0))
  (interactive)
  (aif (directory-name-dialog :title "追加するフォルダを選択")
      (long-operation
	(handler-case
	    (progn
	      (vbmp3-db-execute "BEGIN;")
	      (message "Reading directory...")
	      (dolist (pathname (directory it :absolute t :recursive t))
		(message "Search mp3 file... (~A)" (setq count (1+ count)))
		(vbmp3-db-add-playlist pathname))
	      (message "done")
	      (vbmp3-db-execute "COMMIT;")
	      (%vbmp3-board-left-press *vbmp3-board-current-selected-line-number*)
	      (vbmp3-board-insert))
	  (error (c)
	    (vbmp3-db-execute "ROLLBACK;")
	    (%vbmp3-db-error (format nil "VBMP3-DB-QUERY-ADD-PLAYLIST-FROM-DIRECTORY-NAME-DIALOG: ~A" (si:*condition-string c))))))))
