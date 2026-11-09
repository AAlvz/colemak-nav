;;; colemak-nav.el --- Layout-aware navigation keys for Colemak and friends -*- lexical-binding: t -*-

;; Copyright (C) 2026 AAlvz

;; Author: AAlvz <alfonso@alvz.mx>
;; Maintainer: AAlvz <alfonso@alvz.mx>
;; Assisted-by: Claude Code:claude-opus-5-5
;; URL: https://github.com/AAlvz/colemak-nav
;; Version: 0.1.0
;; Package-Requires: ((emacs "29.1"))
;; Keywords: convenience, keyboard

;; This file is not part of GNU Emacs.

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;; colemak-nav adds a small layer of navigation keys on top of stock
;; Emacs.  It does not remap anything: every key it binds is a chord
;; Emacs leaves free, so the default bindings keep working.
;;
;; Keys are defined by where they sit on the keyboard, not by the letter
;; printed on them.  With the default settings, holding Alt+Shift and
;; tapping the right hand's inverted T moves between windows:
;;
;;   Colemak, Colemak-DH   M-U up   M-N left   M-E down   M-I right
;;   QWERTY                M-I up   M-J left   M-K down   M-L right
;;
;; Three options decide the keys:
;;
;;   `colemak-nav-layout'     the keyboard layout you type on
;;   `colemak-nav-scheme'     which physical keys are the arrows:
;;                            `inverted-t' (QWERTY i j k l) or
;;                            `positional' (vim's QWERTY h j k l)
;;   `colemak-nav-modifiers'  the modifiers held, by default Meta+Shift
;;
;; Enable it with (colemak-nav-mode 1).  `colemak-nav-show-keys' prints
;; the keys the current settings produce.
;;
;; Meta+Shift works in a text terminal too: Alt+Shift+u arrives as ESC U,
;; which Emacs reads as M-U and tells apart from M-u.

;;; Code:

(require 'windmove)

(defgroup colemak-nav nil
  "Layout-aware navigation keys."
  :group 'convenience
  :prefix "colemak-nav-")

;;;; Layouts

;; Each layout is the 30 letter keys, three rows of ten, read left to
;; right and top to bottom, in the same physical positions as `qwerty'.
;; Only these 30 keys are translated; nothing else moves.
(defconst colemak-nav-layouts
  '((qwerty     . "qwertyuiopasdfghjkl;zxcvbnm,./")
    (colemak    . "qwfpgjluy;arstdhneiozxcvbkm,./")
    (colemak-dh . "qwfpbjluy;arstgmneiozxcdvkh,./")
    (dvorak     . "',.pyfgcrlaoeuidhtns;qjkxbmwvz")
    (workman    . "qdrwbjfup;ashtgyneoizxmcvkl,./"))
  "Letter-key diagrams by layout, all aligned to QWERTY positions.
Colemak-DH is the ANSI variant; the ISO one differs only on the bottom
row, which colemak-nav does not use.")

(defconst colemak-nav--base 'qwerty
  "Layout the schemes below are written in.")

(defun colemak-nav--translate (char layout)
  "Return the key of LAYOUT in the position CHAR has on QWERTY."
  (let ((from (alist-get colemak-nav--base colemak-nav-layouts))
        (to (or (alist-get layout colemak-nav-layouts)
                (error "Unknown colemak-nav layout: %s" layout))))
    (aref to (or (seq-position from char)
                 (error "Key %c is not on the letter rows" char)))))

;;;; Schemes and groups

(defconst colemak-nav-schemes
  '((inverted-t (up . ?i) (left . ?j) (down . ?k) (right . ?l))
    (positional (left . ?h) (down . ?j) (up . ?k) (right . ?l)))
  "Direction to physical key, written as the QWERTY letter in that spot.")

(defconst colemak-nav-groups
  '((windows (up    . windmove-up)
             (left  . windmove-left)
             (down  . windmove-down)
             (right . windmove-right)))
  "Command for each direction, by group.")

;;;; Options

(defvar colemak-nav-mode-map (make-sparse-keymap)
  "Keymap of `colemak-nav-mode', rebuilt from the options.")

(defun colemak-nav--set (symbol value)
  "Set SYMBOL to VALUE and rebuild the keymap."
  (set-default-toplevel-value symbol value)
  (when (fboundp 'colemak-nav--rebuild)
    (colemak-nav--rebuild)))

(defcustom colemak-nav-layout 'colemak
  "Keyboard layout you type on."
  :type '(choice (const qwerty) (const colemak) (const colemak-dh)
                 (const dvorak) (const workman))
  :set #'colemak-nav--set
  :initialize #'custom-initialize-default)

(defcustom colemak-nav-scheme 'inverted-t
  "Which physical keys act as arrows.
`inverted-t' uses the keys under QWERTY i j k l (Colemak u n e i): up,
left, down, right, like arrow keys and Colemak's Extend layer.
`positional' uses vim's QWERTY h j k l (Colemak h n e i): left, down,
up, right."
  :type '(choice (const inverted-t) (const positional))
  :set #'colemak-nav--set
  :initialize #'custom-initialize-default)

(defcustom colemak-nav-modifiers '(meta shift)
  "Modifiers held together with the arrow keys.
The default, Meta+Shift, is free in stock Emacs and works in text
terminals.  `super' is free too, but terminals do not send it."
  :type '(set (const control) (const meta) (const shift)
              (const super) (const hyper) (const alt))
  :set #'colemak-nav--set
  :initialize #'custom-initialize-default)

(defcustom colemak-nav-enabled-groups '(windows)
  "Groups of keys to bind.  Each is an entry of `colemak-nav-groups'."
  :type '(set (const windows))
  :set #'colemak-nav--set
  :initialize #'custom-initialize-default)

;;;; Building keys

(defun colemak-nav--key (char modifiers)
  "Return the key vector for CHAR held with MODIFIERS.
Shift on a letter becomes the upper-case letter, because that is the
event Emacs receives: Alt+Shift+u is Meta with an upper-case U, never
Meta and Shift with a lower-case u."
  (let ((mods modifiers))
    (when (and (memq 'shift mods) (<= ?a char ?z))
      (setq char (upcase char)
            mods (remq 'shift mods)))
    (vector (event-convert-list (append mods (list char))))))

(defun colemak-nav-bindings ()
  "Return the (KEY . COMMAND) pairs the current options produce."
  (let ((scheme (alist-get colemak-nav-scheme colemak-nav-schemes)))
    (unless scheme
      (error "Unknown colemak-nav scheme: %s" colemak-nav-scheme))
    (mapcan
     (lambda (group)
       (mapcar (lambda (entry)
                 (let ((pos (alist-get (car entry) scheme)))
                   (cons (colemak-nav--key
                          (colemak-nav--translate pos colemak-nav-layout)
                          colemak-nav-modifiers)
                         (cdr entry))))
               (or (alist-get group colemak-nav-groups)
                   (error "Unknown colemak-nav group: %s" group))))
     colemak-nav-enabled-groups)))

(defun colemak-nav--rebuild ()
  "Refill `colemak-nav-mode-map' from the current options.
The keymap object is kept, so an enabled mode picks up the change."
  (setcdr colemak-nav-mode-map nil)
  (pcase-dolist (`(,key . ,command) (colemak-nav-bindings))
    (define-key colemak-nav-mode-map key command)))

(colemak-nav--rebuild)

;;;; Mode

;;;###autoload
(define-minor-mode colemak-nav-mode
  "Global minor mode for layout-aware navigation keys.
It is a minor mode so its keys win over major modes that would
otherwise swallow them, such as vterm sending every Meta chord to the
shell.  See `colemak-nav-show-keys' for the keys in effect.

\\{colemak-nav-mode-map}"
  :global t
  :lighter nil
  :keymap colemak-nav-mode-map
  :group 'colemak-nav)

(defun colemak-nav-show-keys ()
  "Show the keys colemak-nav binds with the current options."
  (interactive)
  (message "colemak-nav (%s, %s): %s"
           colemak-nav-layout colemak-nav-scheme
           (mapconcat (lambda (b) (format "%s %s" (key-description (car b)) (cdr b)))
                      (colemak-nav-bindings) ", ")))

(provide 'colemak-nav)
;;; colemak-nav.el ends here
