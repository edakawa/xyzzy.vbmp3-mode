;;; -*- Mode: Lisp; Package: VBMP3-FFI -*-

;;; $Id: vbmp3-ffi.l,v 1.1.1.1 2018/09/08 15:25:12 hajime Exp $

;;; vbmp3-ffi.l --- Foreign Function Interface of VBMP3.DLL

;; Author: Hajime EDAKAWA <hajime.edakawa@gmail.com>
;; License: Public Domain
;; Last Update: Mar 2010

;; This file is part of xyzzy.

;;; Commentary:

;; This is FFI package of VBMP3.DLL. These FFI functions are to call for
;; VBMP3's export function directly, but, since it is critical, please
;; use vbmp3-wrapper functions.

;;; Code:

(provide "vbmp3/vbmp3-ffi")

(eval-when (:compile-toplevel :load-toplevel :execute)
  (require "foreign")
  (require "wip/winapi")
  (unless (find-package "vbmp3")
    (defpackage "vbmp3")))

(in-package "vbmp3")


;;; Variable

(defconstant +vbmp3-dll+ "VBMP3.DLL")


;;; Definition of data structure

(c:*define INFO_NAME_SIZE 128)

(c:*define-c-struct InputInfo
  (winapi:CHAR szTrackName  INFO_NAME_SIZE)
  (winapi:CHAR szArtistName INFO_NAME_SIZE)
  (winapi:INT  channels)
  (winapi:INT  bitRate)
  (winapi:INT  samplingRate)
  (winapi:INT  totalSec))

(c:*define-c-struct EQUALIZER
  (c:int  60Hz)
  (c:int 170Hz)
  (c:int 310Hz)
  (c:int 600Hz)
  (c:int  1KHz)
  (c:int  3KHz)
  (c:int  6KHz)
  (c:int 12KHz)
  (c:int 14KHz)
  (c:int 16KHz))

(c:*define-c-struct TAG_INFO
  (c:char szTrackName  128)
  (c:char szArtistName 128)
  (c:char szAlbumName  128)
  (c:char szYear         5)
  (c:char szComment    128)
  (c:int  genre)
  (c:char szGenreName  128))

(c:*define-c-struct TAG_INFO_11
  (c:char szTrackName  128)
  (c:char szArtistName 128)
  (c:char szAlbumName  128)
  (c:char szYear         5)
  (c:char szComment    128)
  (c:int  genre)
  (c:char szGenreName  128)
  (c:int  trackNo))

(c:*define-c-struct MPEG_INFO
  (c:int version)
  (c:int layer)
  (c:int crcDisable)
  (c:int extension)
  (c:int mode)
  (c:int copyright)
  (c:int original)
  (c:int emphasis)
  (c:int channels)
  (c:int bitrate)
  (c:int samplingRate)
  (c:int fileSize)
  (c:int frames)
  (c:int totalSec))


;;; Definition of VBMP3's export function

(c:*define-dll-entry c:int       vbmp3_getFileType      (winapi:PSZ)                               +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_setEqualizer     ((c:int *))                                +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_init             ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_free             ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_open             (winapi:PSZ (InputInfo *))                 +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_close            ()                                         +vbmp3-dll+)
(c:*define-dll-entry c:int       vbmp3_getState         (c:int)                                    +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_play             ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_stop             ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_pause            ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_restart          ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_seek             (c:int)                                    +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_reload           ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_setSoftVolume    (c:int c:int)                              +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_getSoftVolume    (c:int c:int)                              +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_setStepPitch     (c:int c:int)                              +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_setPitch         (c:int)                                    +vbmp3-dll+)
(c:*define-dll-entry c:int       vbmp3_getPitch         ()                                         +vbmp3-dll+)
(c:*define-dll-entry c:int       vbmp3_getVersion       ()                                         +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_setTagInfoEX     (winapi:PSZ (TAG_INFO_11 *) c:int c:int)   +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_getFileTagInfoEX (winapi:PSZ (TAG_INFO_11 *))               +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_getFileInfo      (winapi:PSZ (TAG_INFO_11 *) (MPEG_INFO *)) +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_getGenre         ((TAG_INFO *))                             +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_getMpegInfo      ((MPEG_INFO *))                            +vbmp3-dll+)
(c:*define-dll-entry winapi:BOOL vbmp3_cutID3v2         (winapi:PSZ)                               +vbmp3-dll+)
