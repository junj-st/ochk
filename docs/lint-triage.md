# ochk real-world triage (v0.1)

Run with OCaml 5.3.0, default rules (SL001 + SL002).

| Project | .cmt files | Findings | Verdict |
|---|---|---|---|
| ostd (this repo) | all | 0 (10 SL003 with `--generic`, all in `Safe.Poly`, suppressed with `[@@@ochk.allow "SL003"]`) | justified |
| re 1.14.0 | 68 | 1 × SL002: `Hashtbl.hash m.pmarks` on `Pmark.Set.t` (`lib/automata.ml:327`) | true positive: two equal balanced-tree sets can have different shapes and so different hashes |
| yojson 3.0.0 | 41 | 0 | — |

## False positives found and fixed

- `l <> []`, `x = None`, `` v = `A ``: comparing against a constant constructor
  or literal never inspects the other operand, so it cannot raise or depend on
  representation. `re` had three of these (`emacs.ml`, `perl.ml`, `posix.ml`).
  The linter now skips any target application with a constant argument.
