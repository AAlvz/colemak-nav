# Roadmap

Ideas waiting for real use to decide them. Nothing here is promised.

## Next

- **Test on Windows Terminal (WSL).** Windows Terminal has its own Alt+Shift
  shortcuts (Alt+Shift+D duplicates a pane, Alt+Shift+arrows resize panes).
  None should collide with the letters colemak-nav uses, but it has not been
  checked.
- **Release 0.1.0.** Tag it so the changelog stops saying "unreleased". MELPA
  later, once the keys have settled.

## Ideas

- **Window management group.** Split right, split below, close, maybe swap,
  so windows are as quick to arrange as to move between. The free Meta+Shift
  letters are mostly on the left hand, which feels far on a laptop keyboard,
  so the hard part is picking the keys.
- **Held-key acceleration.** Once a movement key repeats for ~0.1 s, move two
  lines or characters per repeat. It works well in the author's config
  (advice on `next-line`, `previous-line`, `forward-char`, `backward-char`,
  `right-char`, `left-char`), and could become an optional group here.
  Words (`M-f` / `M-b`) and pages are candidates too.

## Decided against

- **A word-selection key** (Meta+Shift+t for an improved `mark-word`).
  `M-@` is close enough and needs no new key.
- **Tabs on the keys right below `n e i`.** With Shift those are `M-M`,
  `M-<` and `M->`; the last two are beginning and end of buffer. See
  [gotchas](gotchas.md#shift-on-punctuation-is-another-character).
