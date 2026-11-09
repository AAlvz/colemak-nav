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
       (let ,bindings
         (colemak-nav--rebuild)
         ,@body)
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

(provide 'colemak-nav-test)
;;; colemak-nav-test.el ends here
