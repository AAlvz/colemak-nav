EMACS ?= emacs
BATCH = $(EMACS) -Q --batch -L .

.PHONY: all test compile lint clean

all: compile lint test

test:
	$(BATCH) -L test -l test/colemak-nav-test.el -f ert-run-tests-batch-and-exit

compile:
	$(BATCH) --eval '(setq byte-compile-error-on-warn t)' -f batch-byte-compile colemak-nav.el

# package-lint comes from MELPA; it is fetched into a throwaway directory.
lint:
	$(BATCH) --eval '(checkdoc-file "colemak-nav.el")'
	$(BATCH) --eval "(progn \
	  (setq package-user-dir (expand-file-name \".lint-elpa\")) \
	  (require 'package) \
	  (add-to-list 'package-archives '(\"melpa\" . \"https://melpa.org/packages/\") t) \
	  (package-initialize) \
	  (unless (package-installed-p 'package-lint) \
	    (package-refresh-contents) (package-install 'package-lint)) \
	  (require 'package-lint))" \
	  -f package-lint-batch-and-exit colemak-nav.el

clean:
	rm -rf *.elc test/*.elc .lint-elpa
