# Gotchas

Things that look simple and are not, collected while building colemak-nav.
Read this before adding a layout, a group, or a new key.

## `colemak-nav-layout` means the letters Emacs receives

Emacs never sees physical keys. Your keyboard and your OS turn each key press
into a letter first, and Emacs only gets the letter. colemak-nav uses QWERTY
letters as names for physical positions, and only at setup time, to work out
which letters to bind. While you type, nothing is translated: Emacs sees `U` and
looks up `M-U`.

So the setting describes the **whole chain**, not the OS layout:

```
physical key → keyboard firmware → OS layout → Emacs
```

Example: a keyboard that remaps to Colemak in firmware, plugged into a Mac set
to *U.S. International*. The firmware sends Colemak, the OS passes the letters
through, and Emacs gets Colemak, so the right setting is `colemak` even though
the OS says "US".

**Quick check:** press the key under your right middle finger on the home row.
`e` means Colemak or Colemak-DH, `k` means QWERTY, `t` means Dvorak.

Nothing can detect this automatically. A firmware remap is invisible to the OS
and to Emacs.

## Shift on a letter is an upper-case letter

Alt+Shift+u reaches Emacs as `M-U` (Meta + upper-case U), not as `M-S-u`
(Meta + Shift + u). A binding on `M-S-u` exists but never fires.
`colemak-nav--key` folds Shift into the letter for this reason. Shift is only
kept as a modifier for non-letters.

Related: when `M-U` is unbound, Emacs falls back to `M-u`. Binding `M-U`
removes that fallback, which in stock Emacs means Alt+Shift+u no longer runs
`upcase-word`.

## Terminals send Meta as ESC, and some ESC pairs start escape sequences

In a text terminal, Alt+x is sent as `ESC x`. Two of those pairs are also how
the terminal starts the escape sequences for arrows and function keys:

| Pair | Sequence | Used for |
|------|----------|----------|
| `ESC O` | SS3 | arrows (application mode), F1–F4 |
| `ESC [` | CSI | arrows, Home/End, PgUp/PgDn, modifyOtherKeys |

Emacs keeps these as prefixes in `input-decode-map`, so after `ESC O` it waits
for the rest of a sequence. **Never bind `M-O` or `M-[`.** With Meta+Shift this
rules out the Colemak `o` position (QWERTY `;` → Colemak `o` → `M-O`), and any
layout whose generated key lands on `O`.

Measured in Emacs 31.1, `emacsclient -nw` on macOS:
`(keymapp (lookup-key input-decode-map "\eO"))` is `t` on the tty frame.

## Control chords a terminal cannot tell apart

| You press | Terminal sends | Same as |
|-----------|----------------|---------|
| `C-i` | `0x09` | `TAB` |
| `C-m` | `0x0D` | `RET` |
| `C-[` | `0x1B` | `ESC` (so a Meta prefix) |
| `C-M-i` | `ESC TAB` | `M-TAB` |
| `C-S-x` | same as `C-x` | – |

GUI Emacs, and terminals using modifyOtherKeys or the kitty protocol, can
separate them, but a portable default must not rely on that. This is one reason
the default modifier is Meta+Shift rather than Control+Meta.

## Super does not reach terminal Emacs

`s-` chords are free in stock Emacs, but terminals do not send Super (the
Windows or Cmd key). It is fine as a GUI-only choice through
`colemak-nav-modifiers`, never as the default.

## macOS: Option has to be Meta

In Terminal.app this is "Use Option as Meta key". In iTerm2 it is "Left Option
key: Esc+". Without it, Option+letter types a special character (US
International and other layouts with dead keys make this worse), and no `M-`
chord works at all.

## Why a minor mode, and where it still loses

Emacs looks keys up in this order (simplified):

1. `overriding-terminal-local-map` / `overriding-local-map` (isearch, transient)
2. `emulation-mode-map-alists` (company's pop-up, among others)
3. **minor-mode maps** ← colemak-nav
4. the buffer's local map (major mode: vterm, magit, org, the minibuffer)
5. `global-map`

- **It wins over major modes.** vterm sends every Meta chord to the shell
  through its major-mode map, so a global binding never fires there, but a
  minor-mode binding does.
- **isearch and company win over us**, so their keys are never stolen.
- **The minibuffer loses to us.** Its keys are a local map, so anything bound by
  colemak-nav also wins at `M-x`, `find-file` and other prompts. Avoid keys
  that matter there (`M-n`/`M-p` history, `M-r`/`M-s`).

## Why not plain `M-u/n/e/i`

It was the first idea, and it was rejected. Those keys are used everywhere:
`M-u` upcase-word; `M-n` minibuffer/vertico history, isearch history, company,
magit sections, `diff-hunk-next`, compilation/occur next, git-commit history,
markdown next link; `M-e` forward-sentence and isearch history; `M-i`
tab-to-tab-stop. A binding that wins everywhere would break all of them.
Meta+Shift letters are almost all unbound.

Before claiming a new key, run a conflict probe against every loaded keymap in
a real configuration, not only `emacs -Q`:

```elisp
(let (out)
  (mapatoms
   (lambda (s)
     (when (and (boundp s) (string-suffix-p "-map" (symbol-name s))
                (keymapp (symbol-value s)))
       (let ((b (ignore-errors (lookup-key (symbol-value s) (kbd "M-L") t))))
         (when (and b (not (numberp b)))
           (push (cons s b) out))))))
  out)
```
