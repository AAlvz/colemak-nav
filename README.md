# colemak-nav

Layout-aware navigation keys for Emacs, built for Colemak and usable on any layout.

colemak-nav adds a small layer of keys on top of stock Emacs. It **does not
remap anything**. Every key it binds is a chord Emacs leaves free, so
`C-n`, `M-n`, `M-u` and the rest keep doing what they always did, and your
muscle memory still works in anyone else's Emacs.

Keys are defined by **where they sit on the keyboard**, not by the letter
printed on them, so the same configuration means the same hand movement on
Colemak, Colemak-DH, QWERTY, Dvorak or Workman.

## Keys

Hold **Alt+Shift** and use the right hand's inverted T to move between windows:

| Direction | Colemak / Colemak-DH | QWERTY | Command |
|-----------|----------------------|--------|---------|
| up        | `M-U`                | `M-I`  | `windmove-up` |
| left      | `M-N`                | `M-J`  | `windmove-left` |
| down      | `M-E`                | `M-K`  | `windmove-down` |
| right     | `M-I`                | `M-L`  | `windmove-right` |

Hold the modifiers and tap as many times as you like; let go and you are
typing again. There is no mode to enter or leave.

`M-x colemak-nav-show-keys` prints the keys your settings produce.

## Why Meta+Shift

Plain `M-u/n/e/i` are taken: `upcase-word`, minibuffer history, magit
sections, next error, and more. `C-M-` chords are structural navigation, and
in a terminal `C-M-i` cannot be told apart from `M-TAB`. Super is free but
terminals do not send it.

Meta+Shift letters are unbound in stock Emacs, and they work in text
terminals: Alt+Shift+u arrives as `ESC U`, which Emacs reads as `M-U` and
tells apart from `M-u`.

colemak-nav is a minor mode, so its keys also work in buffers whose major
mode would otherwise swallow them, such as vterm sending every Meta chord to
the shell.

## Install

Emacs 29.1 or later.

```elisp
(package-vc-install "https://github.com/AAlvz/colemak-nav")
(colemak-nav-mode 1)
```

or with use-package:

```elisp
(use-package colemak-nav
  :vc (:url "https://github.com/AAlvz/colemak-nav")
  :config (colemak-nav-mode 1))
```

## Configuration

| Option | Default | Values |
|--------|---------|--------|
| `colemak-nav-layout` | `colemak` | `qwerty`, `colemak`, `colemak-dh`, `dvorak`, `workman` |
| `colemak-nav-scheme` | `inverted-t` | `inverted-t`: the keys under QWERTY `i j k l` (up, left, down, right). `positional`: vim's QWERTY `h j k l` (left, down, up, right) |
| `colemak-nav-modifiers` | `(meta shift)` | any of `control meta shift super hyper alt` |
| `colemak-nav-enabled-groups` | `(windows)` | groups of keys to bind |

Change them with `M-x customize-group RET colemak-nav`, or with `setopt`,
and the keymap is rebuilt immediately:

```elisp
(setopt colemak-nav-layout 'colemak-dh
        colemak-nav-scheme 'positional)   ; M-M M-N M-E M-I
```

Both schemes have their followers. `inverted-t` matches arrow keys and
Colemak's Extend layer, and does not move on Colemak-DH. `positional` keeps
vim's `hjkl` muscle memory (`h n e i` on Colemak, `m n e i` on Colemak-DH).

## How layouts work

Each layout is stored as its 30 letter keys, aligned to QWERTY positions.
Bindings are written once against QWERTY and translated by position, so
adding a layout is one line in `colemak-nav-layouts`. The idea comes from
[xah-fly-keys](https://github.com/xahlee/xah-fly-keys).

## Gotchas

What the layout setting really means (the letters Emacs receives, not your OS
layout), why `M-O` can never be bound in a terminal, and other traps:
[docs/gotchas.md](docs/gotchas.md).

## Development

```sh
make          # compile, lint, test
make test
```

## License

GPL-3.0-or-later.
