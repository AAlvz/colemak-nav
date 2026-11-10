# Changelog

All notable changes to colemak-nav. Versions follow [semver](https://semver.org).

## 0.1.0 — unreleased

### Added

- `colemak-nav-mode`: global minor mode that moves between windows with
  Meta+Shift and the right hand's inverted T (Colemak `M-U M-N M-E M-I`).
- Layouts: QWERTY, Colemak, Colemak-DH, Dvorak, Workman, translated by
  physical position.
- Schemes: `inverted-t` and `positional` (vim's hjkl positions).
- Configurable modifiers; the keymap rebuilds when an option changes.
- `colemak-nav-show-keys`.
- Buffers group: previous/next buffer on the keys around the up key
  (Colemak `M-L` / `M-Y`), and `colemak-nav-last-buffer` on `M-H` to flip
  between the two most recent buffers of the selected window.
- Tabs group: previous/next tab on the two bottom-row keys below the left
  arrow (Colemak `M-K` / `M-M`).
- Keys that would land on `M-O` (ESC O in terminals) fall back to another
  position, or warn when they cannot.
