;;; colemak-nav-test.el --- Tests for colemak-nav -*- lexical-binding: t -*-

;;; Commentary:

;; Run with `make test'.

;;; Code:

(require 'ert)
(require 'colemak-nav)

(defmacro colemak-nav-test--with (bindings &rest body)
  "Run BODY with the options in BINDINGS, then restore the keymap."
  (declare (indent 1))
  `(unwind-protect
       (let ((colemak-nav-enabled-groups '(windows)))
         (let ,bindings
           (colemak-nav--rebuild)
           ,@body))
     (colemak-nav--rebuild)))

(defun colemak-nav-test--keys ()
  "Current bindings as (\"KEY\" . COMMAND)."
  (mapcar (lambda (b) (cons (key-description (car b)) (cdr b)))
          (colemak-nav-bindings)))

(ert-deftest colemak-nav-test-layouts-aligned ()
  "Every layout has the same 30 keys as QWERTY, each once."
  (dolist (layout colemak-nav-layouts)
    (should (= 30 (length (cdr layout))))
    (should (= 30 (length (delete-dups (string-to-list (cdr layout))))))))

(ert-deftest colemak-nav-test-colemak-inverted-t ()
  (colemak-nav-test--with ((colemak-nav-layout 'colemak)
                           (colemak-nav-enabled-groups '(windows))
                           (colemak-nav-scheme 'inverted-t)
                           (colemak-nav-modifiers '(meta shift)))
    (should (equal (colemak-nav-test--keys)
                   '(("M-U" . windmove-up) ("M-N" . windmove-left)
                     ("M-E" . windmove-down) ("M-I" . windmove-right))))))

(ert-deftest colemak-nav-test-colemak-dh-same-as-colemak ()
  "The inverted T does not move on Colemak-DH."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak-dh)
                           (colemak-nav-scheme 'inverted-t))
    (should (equal (mapcar #'car (colemak-nav-test--keys))
                   '("M-U" "M-N" "M-E" "M-I")))))

(ert-deftest colemak-nav-test-qwerty ()
  (colemak-nav-test--with ((colemak-nav-layout 'qwerty)
                           (colemak-nav-scheme 'inverted-t))
    (should (equal (mapcar #'car (colemak-nav-test--keys))
                   '("M-I" "M-J" "M-K" "M-L")))))

(ert-deftest colemak-nav-test-positional ()
  "Vim positions: h n e i on Colemak, m n e i on Colemak-DH."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak)
                           (colemak-nav-scheme 'positional))
    (should (equal (colemak-nav-test--keys)
                   '(("M-E" . windmove-up) ("M-H" . windmove-left)
                     ("M-N" . windmove-down) ("M-I" . windmove-right)))))
  (colemak-nav-test--with ((colemak-nav-layout 'colemak-dh)
                           (colemak-nav-scheme 'positional))
    (should (equal (car (rassq 'windmove-left (colemak-nav-test--keys)))
                   "M-M"))))

(ert-deftest colemak-nav-test-modifiers ()
  "Without Shift the key stays lower case; Super works too."
  (colemak-nav-test--with ((colemak-nav-modifiers '(super)))
    (should (equal (car (car (colemak-nav-test--keys))) "s-u")))
  (colemak-nav-test--with ((colemak-nav-modifiers '(control meta)))
    (should (equal (car (car (colemak-nav-test--keys))) "C-M-u"))))

(ert-deftest colemak-nav-test-shift-is-uppercase ()
  "Meta+Shift+u must be the event a keyboard sends: M-U, not M-S-u."
  (should (equal (colemak-nav--key ?u '(meta shift)) (kbd "M-U"))))

(ert-deftest colemak-nav-test-keymap-follows-options ()
  "The mode's keymap is rebuilt in place when an option changes."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak))
    (should (eq (lookup-key colemak-nav-mode-map (kbd "M-N")) 'windmove-left))
    (let ((colemak-nav-layout 'qwerty))
      (colemak-nav--rebuild)
      (should (eq (lookup-key colemak-nav-mode-map (kbd "M-J")) 'windmove-left))
      (should-not (lookup-key colemak-nav-mode-map (kbd "M-N"))))))

(ert-deftest colemak-nav-test-unknown-layout ()
  (let ((colemak-nav-layout 'azerty))
    (should-error (colemak-nav-bindings))))

(ert-deftest colemak-nav-test-moves-windows ()
  "M-I moves to the window on the right in a real split."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak))
    (save-window-excursion
      (delete-other-windows)
      (let ((left (selected-window))
            (right (split-window-right)))
        (colemak-nav-mode 1)
        (unwind-protect
            (progn
              (execute-kbd-macro (kbd "M-I"))
              (should (eq (selected-window) right))
              (execute-kbd-macro (kbd "M-N"))
              (should (eq (selected-window) left)))
          (colemak-nav-mode -1))))))

;;;; Buffers

(ert-deftest colemak-nav-test-buffers-colemak ()
  "Colemak: l and y around the up key, h for the last buffer."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak)
                           (colemak-nav-scheme 'inverted-t)
                           (colemak-nav-enabled-groups '(buffers)))
    (should (equal (colemak-nav-test--keys)
                   '(("M-L" . previous-buffer) ("M-Y" . next-buffer)
                     ("M-H" . colemak-nav-last-buffer))))))

(ert-deftest colemak-nav-test-buffers-positional-moves-toggle ()
  "Under vim positions h is an arrow, so the toggle falls back to j."
  (colemak-nav-test--with ((colemak-nav-layout 'colemak)
                           (colemak-nav-scheme 'positional)
                           (colemak-nav-enabled-groups '(windows buffers)))
    (let ((keys (colemak-nav-test--keys)))
      (should (equal (car (rassq 'colemak-nav-last-buffer keys)) "M-J"))
      (should (eq (cdr (assoc "M-H" keys)) 'windmove-left))
      ;; No key is bound twice.
      (should (= (length keys) (length (delete-dups (mapcar #'car keys))))))))

(ert-deftest colemak-nav-test-no-duplicate-keys ()
  "No layout and scheme bind the same key twice."
  (dolist (layout (mapcar #'car colemak-nav-layouts))
    (dolist (scheme (mapcar #'car colemak-nav-schemes))
      (colemak-nav-test--with ((colemak-nav-layout layout)
                               (colemak-nav-scheme scheme)
                               (colemak-nav-enabled-groups '(windows buffers)))
        (let ((keys (mapcar #'car (colemak-nav-test--keys))))
          (should (= (length keys) (length (delete-dups (copy-sequence keys))))))))))

(ert-deftest colemak-nav-test-last-buffer-toggles ()
  "The toggle flips between the two most recent buffers of the window."
  (save-window-excursion
    (let ((a (get-buffer-create "*cn-a*"))
          (b (get-buffer-create "*cn-b*"))
          (c (get-buffer-create "*cn-c*")))
      (unwind-protect
          (progn
            (delete-other-windows)
            (set-window-prev-buffers nil nil)
            (switch-to-buffer a)
            (switch-to-buffer b)
            (switch-to-buffer c)
            (colemak-nav-last-buffer)
            (should (eq (current-buffer) b))
            (colemak-nav-last-buffer)
            (should (eq (current-buffer) c))
            (colemak-nav-last-buffer)
            (should (eq (current-buffer) b)))
        (mapc #'kill-buffer (list a b c))))))

(ert-deftest colemak-nav-test-last-buffer-is-per-window ()
  "Each window flips through its own history.
Window 1 shows a then b; window 2 then shows x.  Globally x is the most
recent buffer, but window 1 must go back to a."
  (save-window-excursion
    (let ((a (get-buffer-create "*cn-a*"))
          (b (get-buffer-create "*cn-b*"))
          (x (get-buffer-create "*cn-x*")))
      (unwind-protect
          (progn
            (delete-other-windows)
            (set-window-prev-buffers nil nil)
            (switch-to-buffer a)
            (switch-to-buffer b)
            (let ((one (selected-window)))
              (select-window (split-window-right))
              (switch-to-buffer x)
              (select-window one)
              (colemak-nav-last-buffer)
              (should (eq (current-buffer) a))))
        (mapc #'kill-buffer (list a b x))))))

(ert-deftest colemak-nav-test-qwerty-avoids-meta-o ()
  "On QWERTY the next-buffer key skips o (ESC O trap) and uses p."
  (colemak-nav-test--with ((colemak-nav-layout 'qwerty)
                           (colemak-nav-enabled-groups '(buffers)))
    (should (equal (car (rassq 'next-buffer (colemak-nav-test--keys))) "M-P"))))

(provide 'colemak-nav-test)
;;; colemak-nav-test.el ends here
