;; mjr-flow -*-coding: utf-8 lexical-binding:t; mode:emacs-lisp; fill-column:158 -*-

;; Copyright (c) 2026-2026 Mitch Richling <https://www.mitchr.me>.  All rights reserved.
;;
;; Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:
;;
;; 1. Redistributions of source code must retain the above copyright notice, this list of conditions, and the following disclaimer.
;;
;; 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions, and the following disclaimer in the documentation
;;    and/or other materials provided with the distribution.
;;
;; 3. Neither the name of the copyright holder nor the names of its contributors may be used to endorse or promote products derived from this software without
;;    specific prior written permission.
;;
;; THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
;; IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
;; FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
;; SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR
;; TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

;; Author:      Mitch Richling
;; Version:     0.1
;; Keywords:    mjr-flow
;; URL:         https://github.com/richmit/mjr-flow

;; This file is not part of Emacs

;;; Install:
;; See the README: https://github.com/richmit/mjr-flow/

;;; Commentary:
;; See the README: https://github.com/richmit/mjr-flow/

;;; Code:

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(require 'mjr-buffer-directory)
(require 'mjr-show-buffer)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;###autoload
;; (defgroup mjr-flow nil
;;   "mjr-flow"
;;   :group 'convenience)

;; ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; ;;;###autoload
;; (defcustom mjr-flow-use-ido t
;;   "Use `ido-completing-read' if non-NIL.  Otherwise use `read-answer'.
;; `read-answer' provides a faster, but more terse user interface -- i.e. only one keystroke to select an evaluation method instead of two."
;;   :type 'boolean
;;   :group 'mjr-flow)


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defvar-local mjr-eshell-prefered-directory nil
  "Buffer local variable storing the preferred directory for mjr-eshell to start up an eshell session related to this buffer.

If this variable contains a string that corresponds to an existing directory in the file system, then the value is used as the initial directory for new
eshell sessions for this buffer.  In all other cases the return from mjr-buffer-directory is used.")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr--find-buffer (only-one &rest rest)
  "Search for one (when ONLY-ONE is non-NIL) or more buffer.
Search the buffer list by a series of ANDed together criteria -- i.e. matching buffers must match every provided criteria.
Each criteria consists of a criteria type symbol and a filter value -- provided as two arguments to this function.  The filter
value may be a list in which case it's elements are logically ORed together -- i.e. a buffer matches the criteria if it matches
any of the filter values on the list.  A filter value of nil matches anything.  Criteria types:
  - :mode ............... Find buffers by `major-mode'
  - :dir & :dir-re ...... Find buffers by `mjr-buffer-directory'
  - :name & :name-re .... Find buffers by `buffer-name'
  - :file & :file-re .... Find buffers by `buffer-file-name'
Examples:
  - Find all EShell buffers
      (mjr--find-buffer nil :mode 'eshell-mode)
  - Find ONE EShell buffer
      (mjr--find-buffer t :mode 'eshell-mode)
  - Find an EShell buffer in a particular directory
      (mjr--find-buffer t :mode 'eshell-mode :dir \"/foo/bar/bo/\")
  - Find a all EShell and elisp scratch buffers:
      (mjr--find-buffer nil :mode '(eshell-mode lisp-interaction-mode))"
  (require 'seq)
  (let ((res-list (buffer-list)))
    (cl-loop for (k v) on rest by #'cddr
             for vl = (if (not (listp v)) (list v) v)
             while (and k v)
             when v
             do (setq res-list (cl-case k
                                 (:mode      (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (eq             ve (buffer-local-value 'major-mode b))) vl)) res-list))
                                 (:dir       (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-equal   ve (mjr-buffer-directory b)))           vl)) res-list))
                                 (:dir-re    (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-match-p ve (mjr-buffer-directory b)))           vl)) res-list))
                                 (:name      (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-equal   ve (buffer-name b)))                    vl)) res-list))
                                 (:name-re   (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-match-p ve (buffer-name b)))                    vl)) res-list))
                                 (:file      (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-equal   ve (or (buffer-file-name b) "")))       vl)) res-list))
                                 (:file-re   (cl-remove-if-not (lambda (b) (seq-some (lambda (ve) (string-match-p ve (or (buffer-file-name b) "")))       vl)) res-list))
                                 (otherwise  (error "mjr--find-buffer: Unsupported search keyword: %s" k)))))
    (if only-one
        (car res-list)
        res-list)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-select-window (window)
  "Interactively switch to a visible window in the current frame via a smart mini-buffer menu.
Called non-interactively, we simply select the named window if WINDOW is non-NIL
Three modes of interactive operation:
  * one visible window: behave exactly like `switch-to-buffer'
  * two visible windows: simply switch to the other window
  * more than two visible windows: produce a smart buffer list prompt
    * It will not include the current buffer
    * Only one occurrence is listed for a buffer appearing in multiple windows (the most recently visited one)
    * Some buffers (dired, slime, R, dired, eshell) have names shortened if possible
      * ex: if only one interactive R buffer exists, then it will simply be called *R* if no conflict arises
    * Some buffers (dired & eshell) have a directory name appended if necessary
      * ex: eshell buffers transform to esh:DIRECTORY where DIRECTORY is the last bit of the CWD"
  (interactive (list (let* ((cur-frame  (selected-frame))
                            (cur-window (selected-window))
                            (cur-buffer (window-buffer))
                            (da-windows nil))
                       (dolist (w (window-list cur-frame))
                         (unless (equal cur-buffer (window-buffer w))
                           (setq da-windows (cl-adjoin w da-windows))))
                       (message "%s" da-windows)
                       (if da-windows
                           (if (= 1 (length da-windows))
                               (select-window (car da-windows))
                               (let* ((da-buffers   (mapcar #'window-buffer da-windows))
                                      (da-buf-names (mapcar #'buffer-name da-buffers))
                                      (da-buf-files (mapcar #'buffer-file-name da-buffers))
                                      (da-buf-modes (mapcar (lambda (b) (buffer-local-value 'major-mode b)) da-buffers))
                                      (da-buf-dirs  (mapcar (lambda (b) (replace-regexp-in-string "^.*[/\\]" ""
                                                                                                  (replace-regexp-in-string "[/\\]+$" ""
                                                                                                                            (mjr-buffer-directory b))))
                                                            da-buffers)))
                                 (cl-flet ((short-name (short-name mode) (when (and (= 1(cl-count mode da-buf-modes))
                                                                                    (not (cl-find short-name da-buf-names :test #'equal)))
                                                                           short-name)))
                                   (when-let* ((da-buf-strs (cl-mapcar (lambda (n f m d)
                                                                         (cl-case m
                                                                           (dired-mode          (or (short-name "*dired*" m)
                                                                                                    (concat "dired:" n)))
                                                                           (ess-rdired-mode     (or (short-name "*Rdired*" m)
                                                                                                    (concat "Rdired:" n)))
                                                                           (eshell-mode         (or (short-name "*eshell*" m)
                                                                                                    (concat (string-replace "*eshell*" "esh" n) ":" d "/")))
                                                                           (slime-repl-mode     (or (short-name "*slime*" m) n))
                                                                           (inf-ruby-mode       (or (short-name "*iRuby*" m) n))
                                                                           (inferior-ess-r-mode (or (short-name "*R*"     m) n))
                                                                           (t                             n)))
                                                                       da-buf-names da-buf-files da-buf-modes da-buf-dirs))
                                               (sel-str     (if (and (boundp 'ido-everywhere) ido-everywhere)
                                                                (ido-completing-read "Buffer: " da-buf-strs nil 't)         
                                                                (completing-read "Buffer: "     da-buf-strs nil 't)))
                                               (sel-idx     (cl-position sel-str da-buf-strs :test #'equal)))
                                     (nth sel-idx da-windows)))))))))
  (if window
      (select-window window)
      (call-interactively #'switch-to-buffer)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-dired-for-buffer (buffer &optional alt-op)
  "Switch to dired buffer for default director for BUFFER creating it if necessary.
alt-op alters the behavior
  - 1 ... Dired visiting mjr-buffer-directory.
  - 4 ... (C-u) Dired visiting project root for mjr-buffer-directory. Insert mjr-buffer-directory into this dired if missing.
  - 16 .. (C-u C-u) Dired visiting project root for mjr-buffer-directory."
  (interactive (list (current-buffer) (prefix-numeric-value current-prefix-arg)))
  (let* ((buf-dir       (mjr-buffer-directory))
         (proj-dir      (when (> alt-op 1)
                          (or (locate-dominating-file buf-dir ".git")
                              (locate-dominating-file buf-dir "CMakeLists.txt"))))
         (da-dir        (if (and proj-dir (> alt-op 1))
                            proj-dir
                            buf-dir))
         (da-frame      (selected-frame))
         (da-dired-bufs (dired-buffers-for-dir da-dir))
         (da-dired-wins (mapcar (lambda (b) (get-buffer-window b da-frame)) da-dired-bufs))
         (da-dired-buf  (car da-dired-bufs))
         (da-dired-win  (cl-find-if-not #'null da-dired-wins)))
    (when da-dired-win
      (select-window da-dired-win))
    (if da-dired-buf
        (switch-to-buffer da-dired-buf)
        (dired da-dir))
    (when (equal alt-op 4)
      (dired-maybe-insert-subdir buf-dir))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-eshell (&optional pfx)
  "Start or switch to an existing eshell buffer.
     - Without a prefix argument
       - If a single eshell buffer exits sharing the current buffer's working directory, then switch to that eshell
       - If a multiple eshell buffers exist sharing the current buffer's working directory, show an `ibuffer' with the options
       - If no eshell buffers exit sharing the current buffer's working directory:
         - Ask the user for a CWD for an eshell (default is the current buffer's CWD)
           - If a single eshell buffer exits for the entered directory, then switch to that eshell
           - If a multiple eshell buffers exist for the entered directory, show an `ibuffer' with the options
           - If no eshell buffers exit for the entered directory
             - If the entered directory exists in the file-system, then create a new eshell and switch to it
             - Otherwise ERROR
     - C-u prefix argument
       - If only one eshell buffer exists, then switch to it
       - If multiple eshell buffers exist, then show `ibuffer' with all eshell buffers
       - Otherwise ERROR
     - C-u - or M-- or C-- or negative prefix argument
       - Ask the user for a CWD for an eshell (default is the current buffer's CWD)
         - If the entered directory exists in the file-system, then create a new eshell and switch to it
         - Otherwise ERROR
     - Positive numeric prefix not entered via (C-u without numbers) -- i.e. C-u NUMBERS or M-NUMBERS
       - If an eshell exists with the numeric prefix as index, then switch to it.
       - If no eshell exists with the numeric prefix as index, then create it with current buffer's CWD without asking
     - When switching to an existing buffer, mjr-show-buffer is used.  So we `select-window' if the buffer is visible, and `switch-to-buffer' otherwise."
  (interactive "P")
  (require 'eshell)
  (let* ((buffer-cwd    (mjr-buffer-directory))
         (target-dir    (if (and (stringp mjr-eshell-prefered-directory)
                                 (file-exists-p mjr-eshell-prefered-directory))
                            mjr-eshell-prefered-directory
                            buffer-cwd))
         (esb-all       (cl-remove-if-not (lambda (b) (and (not (string-prefix-p " " (buffer-name b)))
                                                           (equal 'eshell-mode (buffer-local-value 'major-mode b))))
                                          (buffer-list)))
         (esb-all-many  (cdr esb-all))
         (esb-all-one   (and (car esb-all) (not esb-all-many)))
         (esb-trg       (cl-remove-if-not (lambda (b) (string-equal target-dir (mjr-buffer-directory b))) esb-all))
         (esb-trg-many  (cdr esb-trg))
         (esb-trg-one   (and (car esb-trg) (not esb-trg-many)))
         (esb-trg-none  (null esb-trg))
         (pfx-minus     (eq '- pfx))
         (pfx-pos-num   (and (numberp pfx) (>= pfx 0)))
         (pfx-c-u       (and (listp pfx) (car pfx)))
         (min-or-no-trg (or pfx-minus esb-trg-none)))
    (cond (pfx-pos-num (let ((da-buf (get-buffer (format "%s<%d>" eshell-buffer-name pfx))))                                                ;; POS PFX
                         (if da-buf
                             (mjr-show-buffer da-buf)                                                                                       ;;;; POS PFX + existing eshell
                             (eshell pfx))))                                                                                                ;;;; POS PFX + no existing eshell
          (pfx-c-u     (cond (esb-all-many (ibuffer nil "ESHELL BUFFERS" (list (cons 'mode 'eshell-mode))))                                 ;; C-u+ many eshell buffers
                             (esb-all-one  (mjr-show-buffer (car esb-all)))                                                                 ;;;; C-u+ one eshell buffer
                             ('t           (message "mjr-eshell: ERROR: No eshells for ibuffer"))))                                         ;;;; C-u+ mp eshell buffers
          ('t          (progn                                                                                                               ;; Negative prefix, no prefix, or 0 eshell buffers found
                         (cond (min-or-no-trg (let* ((nxt-esh-num  (cl-loop for i from 0                                                    ;;;; Minus PFX or 0 eshell buffers
                                                                            for pbn = (format "%s<%d>" eshell-buffer-name i)
                                                                            for pb  = (get-buffer pbn)
                                                                            when (not pb)
                                                                            return i))
                                                     (esh-cwd      (expand-file-name (ido-read-directory-name "eshell cwd: " target-dir)))
                                                     (esb-cwd      (cl-remove-if-not (lambda (b) (string-equal esh-cwd (mjr-buffer-directory b)))
                                                                                     esb-all))
                                                     (esb-cwd-many (cdr esb-cwd))
                                                     (esb-cwd-one  (and (car esb-cwd) (not esb-cwd-many)))
                                                     (esb-cwd-none (null esb-cwd)))
                                                (if (file-directory-p esh-cwd)
                                                    (progn (setq mjr-eshell-prefered-directory esh-cwd)
                                                           (cond ((or pfx-minus esb-cwd-none) (let ((nesh (eshell nxt-esh-num)))            ;;;;;; no eshell exists for input CWD
                                                                                                (eshell/cd esh-cwd)
                                                                                                (eshell-send-input)))
                                                                 (esb-cwd-many                (ibuffer nil
                                                                                                       "ESHELL BUFFERS"
                                                                                                       (list (cons 'mode      'eshell-mode) ;;;;;; many eshells exist for input CWD
                                                                                                             (cons 'directory esh-cwd))))
                                                                 (esb-cwd-one                 (mjr-show-buffer (car esb-cwd)))))            ;;;;;; one eshell exists for input CWD
                                                    (message "mjr-eshell: ERROR: Input directory is missing!"))))
                               (esb-trg-one   (mjr-show-buffer (car esb-trg)))                                                              ;;;; NO PFX + one eshell buffer
                               (esb-trg-many  (ibuffer nil "ESHELL BUFFERS" (list (cons 'mode       'eshell-mode)                           ;;;; NO PFX + many eshell buffers
                                                                                  (cons 'directory  target-dir))))))))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-window-configuration-to-register-and-zoom (pfx)
  "Store window config to a register, and zoom window.  If window is already zoomed, restore previously saved window config.

With a prefix argument, query for the register to use. Without a prefix argument, the register used will be /w/."
  (interactive "P")
  (if (one-window-p)
      (if pfx
          (call-interactively #'jump-to-register)
          (let ((w-content (get-register ?w)))
            (if (and (listp w-content) (window-configuration-p (car w-content)))
                (set-window-configuration (car w-content))
                (error "ERROR: mjr-window-configuration-to-register-and-zoom): The register w doesn't contain a window configuration"))))
      (progn (if pfx
                 (call-interactively #'window-configuration-to-register)
                 (window-configuration-to-register ?w))
             (delete-other-windows))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-arrange-windows (&optional requested-layout)
  "Arrange related buffers in windows around a main buffer window.

   Examples of related buffers:
     - A buffer  visiting a file, and a dired visiting the directory.
     - An eshell buffer is running inside a buffer's `mjr-eshell-prefered-directory'.
     - A buffer visiting code in an interpreted language, and buffers running an interpreter for that language in the same working directory.
     - A buffer visiting an org-mode file with source blocks and interactive interpreters for those blocks running in the same working directory.
     - A buffer visiting code for a compiled languages (C++, Fortran, C), and a *compilation* buffer.
     - A buffer CMakeLists.txt a *compilation* buffer.
     - A buffer CMakeLists.txt in the root of a git repository, and a vc-dir-mode buffer.

   It's nice to have these buffers all visible and arranged in a standard way.  Once arranged, I normally store the window configuration to a register.  Two
   layouts (numbered 1 & 4) are supported:

                  No Prefix (layout 1)                     With Prefix (layout 4)
                  +------------+---------+                 +-----------+---------+
                  |            |  dired  |                 |           |  dired  |
                  |            +---------+                 |   main    +---------+
                  |            |  other  |                 |           |  other  |
                  |            | windows |                 +-----------+ windows |
                  |   main     |  1 & 4  |                 |           |    4    |
                  |            +---------+                 |   other   +---------+
                  |            | compile |                 |  windows  | compile |
                  |            +---------+                 |     1     +---------+
                  |            | eshell  |                 |           | eshell  |
                  +------------+---------+                 +-----------+---------+

    - A dired buffer is ALWAYS created or reused at the top right
      - It will have the project root directory (location of CMakeLists.txt or .git) if it exists
      - It will also have the CWD inserted.
    - An eshell will always be created or reused at the lower right.
      - If the main buffer's `mjr-eshell-prefered-directory' is non-NIL, the call `mjr-eshell' as if from main buffer
      - If the main buffer's `mjr-eshell-prefered-directory' is NIL
        - Search for a project root (CMakeLists.txt location) or git repository root.
        - If no root is found found, then call `mjr-eshell' as if from main buffer
        - If a root is found, then temporarily set `mjr-eshell-prefered-directory' for main buffer and call `mjr-eshell'.  Note this will *not* result in a
          the main buffer acquiring a local value for `mjr-eshell-prefered-directory'.
    - Between the dired & eshell we have /other/ windows that may appear depending on main buffer mode.
      - The variables `GROUP-1-KIN' & `GROUP-4-KIN' define the other kinds of windows that may be created.
      - The variable `OTHER-OPT' describe the extra buffers
        - Window height on the left (layout 4)
        - Window right (layout 1&4)
        - How to create/select the buffer.
          - If this is nil, then buffers of that mode are selected that share the CWD of the starting buffer.  If multiple buffers of the same mode are found,
            then the last one visited will be used.
          - If it is a lambda, then it is expected to return a buffer.
      - The first of the following options that works determines the window height:
        - All the /other/ windows can be rendered with maximum height. The dired entire contents of dired are be visible. At least least 25 lines for eshell.
        - All the /other/ windows can be rendered with maximum height. The dired & eshell equally share the space. At least least 25 lines for eshell.
        - All right hand buffers can be displaced with equal size such that they are more than 15 lines.
    - Below the main window window group 1 will appear if layout 1 is requested
      - The first of the following options that works determines the window height:
        - All the /other/ windows can be rendered with maximum height. The primary buffer window is at least half the height of the frame.
        - All the /other/ buffers can be rendered with equal size in 1/2 of the frame height."
  (interactive (list (prefix-numeric-value current-prefix-arg)))
  (delete-other-windows)                                                              ;; Wack all the other windows
  (let* ((layout      (if (numberp requested-layout) requested-layout 1))             ;; Default layout is 1
         (left-window (selected-window))                                              ;; ID for the only remaining window
         (max-height  (window-height))                                                ;; Full frame windoow's height
         (main-mode   major-mode)                                                     ;; Master buffer's Mode
         (main-buf    (current-buffer))                                               ;; Master buffer's ID
         (main-name   (buffer-name))                                                  ;; Master buffer's Name
         (main-file   (buffer-file-name))                                             ;; File name for buffre (FQPN)
         (main-dir    (mjr-buffer-directory main-buf))                                ;; Master buffer's directory.  Used to ID "related" buffers
         (git-dir     (locate-dominating-file main-dir ".git"))                       ;; Dir with .git.  May use someday for a vc-dir-mode window
         (cmake-dir   (locate-dominating-file main-dir "CMakeLists.txt"))             ;; CMake source dir
         (proj-dir    (or git-dir cmake-dir main-dir))                                ;; A prefix argument != 1 maps to layout 4 right now
         (right-width 100)                                                            ;; Width of right side windows
         (esh-targ-hi 25)                                                             ;; eshell target height
         (group-4-kin '(("^next-tag\\.org"      (vc-dir-mode))                        ;; Group 4 Modes -- always appear on the riht
                        (org-mode               (inferior-ess-r-mode
                                                 inf-ruby-mode
                                                 slime-repl-mode
                                                 lisp-interaction-mode
                                                 inferior-emacs-lisp-mode
                                                 inferior-octave-mode
                                                 inferior-maxima-mode))
                        (makefile-mode          (vc-dir-mode))
                        (makefile-gmake-mode    (vc-dir-mode))
                        ("^CMakeLists\\.txt"    (vc-dir-mode))
                        ("^CMakePresets\\.json" (vc-dir-mode))
                        (ess-r-mode             (ess-rdired-mode))))
         (group-1-kin '((ruby-mode              (inf-ruby-mode))                      ;; Group 1 Modes -- left "other" windows with prefix
                        (c++-mode               (compilation-mode))
                        (fortran-mode           (compilation-mode))
                        (f90-mode               (compilation-mode))
                        (c-mode                 (compilation-mode))
                        ("^CMakeLists\\.txt"    (compilation-mode))
                        (makefile-mode          (compilation-mode))
                        (makefile-gmake-mode    (compilation-mode))
                        (cmake-mode             (compilation-mode))
                        (lisp-mode              (slime-repl-mode))
                        (octave-mode            (inferior-octave-mode))
                        (emacs-lisp-mode        ("elisp-interactyness"))
                        (ess-r-mode             (inferior-ess-r-mode))
                        (inferior-ess-r-mode    (ess-rdired-mode))))
         (other-opt   '((ess-rdired-mode          15 15  nil)                         ;; Options for other windows (l-max-hi, r-max-hi & get-buf)
                        (inf-ruby-mode            25 25  nil)
                        (inferior-emacs-lisp-mode 25 25  nil)
                        (inferior-ess-r-mode      25 25  nil)
                        (inferior-maxima-mode     25 25  nil)
                        (inferior-octave-mode     25 25  nil)
                        (lisp-interaction-mode    25 25  nil)
                        (slime-repl-mode          25 25  nil)
                        ("elisp-interactyness"    25 40  (or (and main-dir   (or (mjr--find-buffer 't :mode 'inferior-emacs-lisp-mode :dir main-dir)
                                                                                 (mjr--find-buffer 't :mode 'lisp-interaction-mode    :dir main-dir)))
                                                             (and git-dir    (or (mjr--find-buffer 't :mode 'inferior-emacs-lisp-mode :dir git-dir)
                                                                                 (mjr--find-buffer 't :mode 'lisp-interaction-mode    :dir git-dir)))
                                                             (mjr--find-buffer 't :mode 'inferior-emacs-lisp-mode)
                                                             (mjr--find-buffer 't :mode 'lisp-interaction-mode)))
                        (vc-dir-mode              15 15  (when (and main-dir git-dir (string-equal main-dir git-dir))
                                                           (let ((display-buffer-alist '((".*" display-buffer-same-window))))
                                                             (vc-dir git-dir)
                                                             (current-buffer))))
                        (compilation-mode         10 10  (get-buffer "*compilation*")))))
    (when (< max-height     (* 2.0 esh-targ-hi))  (error "mjr-arrange-windows: Window too short for standard layout"))
    (when (< (window-width) (* 2.5 right-width))  (error "mjr-arrange-windows: Window too narrow for standard layout"))
    (cl-flet ((make-buffer-data-list (ml) (cl-loop for m in ml
                                                   for o = (assoc m other-opt)
                                                   for n = (nth 3 o)
                                                   for b = (if n
                                                               (save-excursion
                                                                 (eval n nil))
                                                               (mjr--find-buffer 't :mode m :dir main-dir))
                                                   when b
                                                   collect (append (list b) o)))
              (match-config-list (da-list) (cadr (cl-find-if (lambda (x) (if (stringp (car x))
                                                                             (string-match-p (car x) main-name)
                                                                             (equal          (car x) main-mode)))
                                                             da-list))))
      (let* ((right-modes  (cl-case layout
                             (1 (append (match-config-list group-1-kin)               ;; Layout 1 gets group-1 and group-4 on the right
                                        (match-config-list group-4-kin)))
                             (4 (match-config-list group-4-kin))))                    ;; Layout 4 gets only group-1 on the right
             (right-bufs   (make-buffer-data-list right-modes))                       ;; Find existing buffers matching modes & directory
             (right-count  (length right-bufs))                                       ;; Number of "other windows" on the right
             (right-window (split-window left-window (- right-width) 'right)))        ;; Right window is 100 columns -- so left is normally quite wide
        (select-window right-window t)                                                ;; Select right window so we can make a dired in it
        (if (dired-buffers-for-dir main-dir)                                          ;; Start dired on directory or switch to existing dired visiting directory
            (switch-to-buffer (car (dired-buffers-for-dir main-dir)))
            (progn (dired proj-dir)
                   (dired-maybe-insert-subdir main-dir)))
        (revert-buffer)                                                               ;; refresh dired contents
        (let* ((dired-p-hi (+ 3 (count-lines (point-min) (point-max))))               ;; Size of window perfectly fitted dired contents
               (right-m-hi (cl-loop for bb in right-bufs                              ;; Maximum size for ALL "other" windows
                                    sum (nth 3 bb)))
               (eshell-hi   (if (< esh-targ-hi (- max-height right-m-hi dired-p-hi))  ;; Height of eshell if we have enough space
                                (- max-height right-m-hi dired-p-hi)
                                (1- (truncate (- max-height right-m-hi) 2))))
               (right-hi    (if (> esh-targ-hi eshell-hi)                             ;; Size for right if we can't fit max height
                                (truncate max-height (+ right-count 2)))))
          (when (and right-hi (< right-hi 15))
            (error "mjr-arrange-windows: Insufficient room for right side windows."))
          (let ((tmp (split-window right-window (- (or right-hi eshell-hi)) 'below))) ;; Now make eshell
            (select-window tmp t)
            (switch-to-buffer main-buf)
            (if (buffer-local-value 'mjr-eshell-prefered-directory main-buf)          ;; If we have previously started an eshell, use the dir
                (mjr-eshell nil)
                (if (or proj-dir git-dir)
                    (let ((mjr-eshell-prefered-directory (or proj-dir git-dir)))      ;; Start eshell in project root if it exists
                      (mjr-eshell nil))
                    (mjr-eshell nil))))
          (dolist (bb right-bufs)                                                     ;; Add all the right sub-windows
            (let ((tmp (split-window right-window (- (or right-hi (nth 3 bb))) 'below)))
              (select-window tmp 't)
              (switch-to-buffer (car bb))))))
      (when (= 4 layout)                                                              ;; Layout 4
        (let* ((left-modes (match-config-list group-1-kin))                           ;; group-1 on the left
               (left-bufs  (make-buffer-data-list left-modes))                        ;; Find existing buffers matching modes & directory
               (left-count (length left-bufs)))                                       ;; Number of other buffers on the left
          (when (> left-count 0)
            (let* ((left-m-hi  (cl-loop for bb in left-bufs                           ;; Maximum size for ALL "other" windows
                                        sum (nth 2 bb)))
                   (left-hi    (when (> left-m-hi (truncate max-height 2))            ;; Size for left if we can't fit max height
                                 (truncate (truncate max-height 2) left-count))))
              (when (and left-hi (< left-hi 15))
                (error "mjr-arrange-windows: Insufficient room for left side windows."))
              (dolist (bb left-bufs)                                                  ;; Create all the windows
                (let ((tmp (split-window left-window (- (or left-hi (nth 2 bb))) 'below)))
                  (select-window tmp 't)
                  (switch-to-buffer (car bb))))))))
      (select-window left-window 't)                                                  ;; Get us back in the upper left window
      (switch-to-buffer main-buf)))                                                   ;; Select original buffer just in case
  (message "mjr-arrange-windows Complete"))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-scratch (&optional mode-to-use content)
  "Create a new scratch buffer with current region's contents and switch to it.  Understands rectangular selections.
The mode for the new buffer is interactively queried.  With prefix argument you can specify an arbitrary mode, without you get a safe list."
  (interactive (list (if (and (null current-prefix-arg) (and (boundp 'ido-everywhere) ido-everywhere))
                         (ido-completing-read "New buffer mode: " (delete-dups (list "lisp-interaction-mode" "text-mode" "org-mode" "mail-mode" (symbol-name major-mode))))
                         (read-string         "New buffer mode: " "lisp-interaction-mode"))))
  (let* ((new-buf-content  (if (region-active-p)
                               (buffer-substring-no-properties (region-beginning) (region-end))
                               ""))
         (new-buf-mode-str (if (not (stringp mode-to-use))
                               "lisp-interaction-mode"
                               mode-to-use))
         (new-buf-mode-sym (let ((mode-sym (intern new-buf-mode-str)))
                             (when (fboundp mode-sym)
                               mode-sym)))
         (new-buf-mode-suf (if (string-equal "lisp-interaction-mode" new-buf-mode-str) "" (concat "-" new-buf-mode-str))))
    (when (string-match "^\\*.*\\*$" (buffer-name))
      (when (y-or-n-p (concat "Delete current buffer (" (buffer-name) ")"))
        (kill-buffer)))
    (unless new-buf-mode-sym
      (error "mjr-scratch: ERROR: MODE-TO-USE was not found"))
    (let* ((new-buf-name (generate-new-buffer-name (concat "*scratch" new-buf-mode-suf "*")))
           (new-buffer   (get-buffer-create new-buf-name)))
      (with-current-buffer new-buffer
        (funcall new-buf-mode-sym)
        (switch-to-buffer-other-window new-buffer)
        (insert new-buf-content)))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-view-file-or-url-at-point ()
  "If point is on a file name or URL, then load with an external viewer/editor.  (open-as with prefix argument on Windows)"
  (interactive)
  (when (and (not (eq system-type 'windows-nt)) current-prefix-arg)
    (error "mjr-view-file-or-url-at-point: Prefix argument only supported on native Windows Emacs"))
  (let ((fap (if (equal major-mode 'dired-mode)
                 (dired-get-filename nil t)
                 (ffap-guess-file-name-at-point))))
    ;; Print message if fap was bad
    (if (not fap)
        (message "mjr-view-file-or-url-at-point: WARNING: Could not find a filename name at point!")
        (unless (or (ffap-url-p fap) (file-exists-p fap))
          (message "mjr-view-file-or-url-at-point: WARNING: File a name at point, but it did not exist in the filesystem: %s" fap)))
    ;; Read filename till we get a good one
    (while (not (and fap (or (ffap-url-p fap) (file-exists-p fap))))
      (setq fap (read-file-name "File to open: ")))
    ;; Act on filename
    (cl-case system-type
      (windows-nt (w32-shell-execute (if current-prefix-arg "openas" "open") fap))
      (darwin     (start-process-shell-command "open" "open" (concat "open " fap)))
      (gnu/linux  (let ((ttr (or (cdr (assoc (upcase (file-name-extension fap)) (list (cons "PDF"  "mjrpdfview")
                                                                                      (cons "JPEG" "mjrimgview")
                                                                                      (cons "JPG"  "mjrimgview")
                                                                                      (cons "GIF"  "mjrimgview")
                                                                                      (cons "PNG"  "mjrimgview"))))
                                 "xdg-open")))
                    (start-process-shell-command ttr ttr (concat ttr " " fap))))
      (otherwise  (message "mjr-view-file-or-url-at-point: ERROR: Found a file, but platform is unknown")))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-follow-mode (cols-or-col-width-or-fill-width-or-percentile)
  "Close all open windows in the current frame; create a number of equal width vertical windows with current buffer; and activate follow-mode.
The value of cols-or-col-width-or-fill-width-or-percentile is used to determine the number of vertical windows:
   1) cols-or-col-width-or-fill-width-or-percentile <-20 => Compute column width such that percentage of lines will fit (min width is 80).  Jump to 3).
   2) cols-or-col-width-or-fill-width-or-percentile <  0 => Compute column width as (or fill-column 80).  Jump to 3).
   3) cols-or-col-width-or-fill-width-or-percentile >  8 => Create as many windows as possible that are at least this width.
   4) cols-or-col-width-or-fill-width-or-percentile == 1 => Create 2 windows
   5) cols-or-col-width-or-fill-width-or-percentile <= 8 => Create as this many windows."
  (interactive "p")
  (let ((cols-or-col-width (if (< cols-or-col-width-or-fill-width-or-percentile 0)
                               (if (< cols-or-col-width-or-fill-width-or-percentile -20)
                                   (let ((ll (sort (mapcar (lambda (x) (length x))                   ;; Percentile
                                                           (string-split (buffer-substring-no-properties (point-min) (point-max))
                                                                         "[\n\r]+")))))
                                     (or (nth (max 0 (1- (truncate (* (abs cols-or-col-width-or-fill-width-or-percentile)
                                                                      (length ll)) 100))) ll) 80))
                                   (if (numberp fill-column)                                        ;; Fill Column
                                       fill-column
                                       2))
                               cols-or-col-width-or-fill-width-or-percentile)))
    (delete-other-windows)
    (let ((cols (if (> cols-or-col-width 8)
                    (max 1 (truncate (window-width) cols-or-col-width))
                    (max 2 cols-or-col-width))))
      (dotimes (i (1- cols))
        (progn (split-window-horizontally)
               (balance-windows)))
      (follow-mode t))))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;###autoload
(defun mjr-open-cwd ()
  "Open buffer's CWD in a file browser (explorer on windows, dolphin or nautilus on Linux)"
  (interactive)
  (let ((target-dir (mjr-buffer-directory)))
    (cl-case system-type
      (windows-nt  (w32-shell-execute "open" target-dir))
      (darwin      (start-process-shell-command "open" "open" (concat "open " target-dir)))
      (gnu/linux   (if-let* ((fme (cl-find-if #'executable-find (list "dolphin" "nautilus"))))
                       (start-process "file-explorer" nil fme (expand-file-name target-dir))
                     (message "mjr-open-cwd: ERROR: Could not find file manager binary"))))))

(provide 'mjr-flow)

;;; filename ends here
