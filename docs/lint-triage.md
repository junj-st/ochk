# ochk real-world survey (v0.1)

## Summary

| Rule | Before look-through | After look-through |
|---|---|---|
| SL001 compare-functional | 2 (1 real) | 2 (1 real) |
| SL002 compare-abstract | 36 (2 real) | **1 (1 real)** |
| SL004 compare-opaque (off by default) | — | 35 |

"Look-through" is ochk following an abstract type to its definition (same
file or the defining unit's `.cmt`) and warning only when the representation
is unsafe to compare. The one SL002 left is `re`'s `Hashtbl.hash` on a `Set`.
The eio `Mtime.t` case (unsigned `int64`, wrong only after ~292 years) is now
SL004, a deliberate trade for precision.

The tables below are the original run, before look-through.

OCaml 5.3.0. 50 popular opam packages were fetched with `opam source`,
type-checked with `dune build -p <pkg> @check`, and linted with
`ochk --generic`. Counts below are for library code only (tests, benchmarks
and examples excluded).

- Packages linted: **47** (cmdliner and caqti produced no `.cmt` files;
  mustache was not reached)
- `.cmt` files: **2,891**
- Findings: **2 × SL001**, **36 × SL002**, 229 × SL003 (SL003 is off by default)

## SL001 (compare-functional): 2 findings

| Package | Location | Verdict |
|---|---|---|
| ounit2 | `oUnitConf.ml:389` `List.sort Stdlib.compare specs` on `Arg` specs | **Latent crash.** Works only while every option name is unique; a duplicate key makes `compare` reach the closures and raise `Invalid_argument "compare: functional value"`. Fix: sort by key with `String.compare`. |
| ocamlformat-lib (vendored compiler code) | `warnings.ml:936` `doc = Format_doc.Doc.empty` | Harmless: comparing with an empty value never reaches closures. ochk only recognises syntactic constants (`[]`), not a named empty value. |

## SL002 (compare-abstract): 36 findings in 7 packages

| Package | Count | Underlying type | Verdict |
|---|---|---|---|
| re | 1 | `Pmark.Set.t` (a `Set`) | **Real, minor.** `Hashtbl.hash` on a balanced tree: equal sets can hash differently, causing cache misses. |
| eio | 1 | `Mtime.t` = unsigned `int64` | **Real in theory.** Signed `<=` on unsigned values is wrong past 2^63 ns (about 292 years of uptime). |
| eio | 13 | `Int63.t` | Harmless. |
| odoc | 15 | variants of `string` / `int`, `Fpath.t` = `string` | Harmless. |
| ipaddr | 3 | `string` | Harmless. |
| zed | 2 | `string` | Harmless. |
| core, menhir, ocamlgraph, lwt | 0 | — | Earlier false positives, fixed (below). |

## Conclusions

1. **SL001 is precise but rare:** 1 real latent bug in 47 packages, 1 harmless.
2. **SL002 was mostly noise as first designed:** 2 of 36 mattered, since most
   abstract types are plain `int` or `string` underneath. Looking through the
   abstraction fixed this (see Summary): SL002 is now 1 finding, and it is
   real.

## False positives found and fixed during the survey

| Pattern | Seen in | Fix |
|---|---|---|
| `l <> []`, `x = None`, `(a, b, c) <> ([], [], [])` | re, lwt | Skip comparisons with constant literals |
| `fun (type k) ... Hashtbl.hash` | containers | Locally abstract types are generic (SL003) |
| `T.t` inside `module Make (T : S)` | menhir, ocamlgraph | Functor-parameter types are generic (SL003) |
| `Unix.file_descr` | lwt | Treated as safe (an `int` on Unix) |
| `[@@deriving compare, equal]` output | core | Skip ppx-generated code |
| `/workspace_root` build dir in release builds | all `-p` builds | Find the real build root from the `.cmt` location |
| Hours-long run on odoc's large recursive types | odoc | Memoize verdicts, cap work per check (reported on stderr) |
