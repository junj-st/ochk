# ostd — implementation plan

*Working name, free on opam as of 2026-10-23; revisit before publishing. Because
the name sounds like the official Stdlib, the README's first line should say it
extends Stdlib rather than replacing it.*

A drop-in extension of the OCaml standard library, plus a linter that catches
polymorphic-comparison bugs. The library fills real gaps without new types or
a new dialect. The linter provides the safety guarantees without forcing
anyone to adopt the library.

## Principles

1. **Stdlib-compatible.** Every extended module starts with `include Stdlib.X`.
   Values of `'a list`, `string`, `'a option`, etc. flow freely between code that
   uses `ostd` and code that doesn't. No `Core`-style replacement types.
2. **Fill gaps; don't duplicate.** Before adding a function, check that Stdlib
   (current release) doesn't already have it. For large domains (regex, time,
   JSON) point to existing libraries (Re, Ptime, Yojson) instead of
   reimplementing.
3. **Safety is opt-in in the library and enforced by the linter.** `open
   Ostd` changes nothing about comparison semantics. `open Ostd.Safe` shadows
   polymorphic comparison. `ostd-lint` flags dangerous uses in any codebase.
4. **Small dependency footprint.** The core library depends only on Stdlib. The
   linter depends only on `compiler-libs`. Tests may use alcotest/qcheck.

## Prior art to review first (half a day)

Read these before writing code. They decide what's actually missing.

- **Containers** (`containers`): closest to this design. Skim `CCList`, `CCString`,
  `CCHeap`, `CCFQueue` for API naming and what people actually use.
- **Base / Core**: how `Base` shadows polymorphic compare; `Comparable` patterns.
- **zanuda** (OCaml linter): check which lints it already has. If it already
  flags polymorphic compare well, contribute there instead of writing SL001–SL003,
  and keep ostd-lint for anything it lacks.
- **Stdlib changelog** for the 5.x series: many old gaps are closed
  (`Dynarray`, `List.is_empty`, `Array.find_index`, `In_channel`, etc.).

Write findings into `docs/gaps.md`: a table of candidate functions and which
library (if any) already provides them.

## Setup

```sh
opam switch create ostd 5.3.0      # or the current 5.x release
eval $(opam env)
opam install dune ocaml-lsp-server ocamlformat odoc alcotest qcheck-core
```

**Minimum supported OCaml for v0.1:** the 5.x release you develop on (e.g. ≥ 5.2).
Supporting older compilers means polyfilling functions Stdlib added later, and
those collide with `include` in `.mli` files. Defer that to v0.2 using dune
`(select ...)` or version-gated rules.

## Repository layout

```
ostd/
├── dune-project
├── PLAN.md
├── docs/
│   └── gaps.md
├── lib/                    # library: ostd
│   ├── dune
│   ├── ostd.ml           # top-level module, re-exports everything
│   ├── ostd_list.ml/.mli
│   ├── ostd_string.ml/.mli
│   ├── ostd_option.ml/.mli
│   ├── ostd_result.ml/.mli
│   ├── ostd_map.ml/.mli
│   ├── ostd_set.ml/.mli
│   ├── heap.ml/.mli        # new data structure
│   ├── deque.ml/.mli       # new data structure
│   └── safe.ml/.mli        # opt-in comparison shadowing
├── lint/                   # executable: ostd-lint
│   ├── dune
│   ├── main.ml             # CLI, walks directories for .cmt files
│   ├── targets.ml          # which Stdlib paths count as polymorphic compare
│   ├── classify.ml         # is it safe to compare values of this type?
│   └── report.ml           # compiler-style output, exit codes
└── test/
    ├── lib/                # alcotest + qcheck tests for the library
    └── lint/               # cram tests with fixture .ml files
```

## Phase 0 — Scaffold (1 evening)

- `dune-project` with `(lang dune 3.14)`, `(generate_opam_files true)`, and two
  packages: `ostd` (library) and `ostd-lint` (executable).
- `git init`, `.ocamlformat` (`profile = default`), `.gitignore` (`_build/`).
- CI: GitHub Actions with `ocaml/setup-ocaml`, running `dune build @all @runtest`
  on your minimum version and the latest 5.x.
- Done when `dune build && dune test` passes on an empty library and CI is green.

`lib/dune`:

```
(library
 (name ostd)
 (public_name ostd))
```

## Phase 1 — Core library (1–2 weeks)

### Module pattern

```ocaml
(* lib/ostd_list.ml *)
include Stdlib.List

let take n l = ...
let drop n l = ...
```

```ocaml
(* lib/ostd_list.mli *)
include module type of Stdlib.List

val take : int -> 'a list -> 'a list
(** [take n l] is the first [n] elements of [l] (all of [l] if shorter).
    Raises [Invalid_argument] if [n < 0]. *)
```

```ocaml
(* lib/ostd.ml *)
module List = Ostd_list
module String = Ostd_string
module Option = Ostd_option
module Result = Ostd_result
module Map = Ostd_map
module Set = Ostd_set
module Heap = Heap
module Deque = Deque
module Safe = Safe
```

Users write `open Ostd` and get extended modules in place of the Stdlib ones.

### Candidate API (confirm each against `docs/gaps.md`)

**List**: `take`, `drop`, `take_while`, `drop_while`, `split_at`, `chunks`,
`windows`, `group_by` (takes an equality function), `last`, `last_opt`,
`sum`/`sum_float`, `max_by`/`min_by` (take a key or compare function, never
polymorphic compare), `dedup ~compare`, `zip`/`unzip` (returning options or
raising on length mismatch; pick one and document it), `index_of ~eq`.

**String**: `split_on ~sep` (substring separator, not just char), `replace_all
~sub ~by`, `contains_sub`, `find_sub`, `pad_left`/`pad_right`,
`trim_left`/`trim_right`, `chop_prefix`/`chop_suffix` (returning options),
`lines`, `is_blank`. Be explicit in docs that these operate on bytes, not
Unicode scalars.

**Option / Result**: `Syntax` submodules with `let*`, `let+`, `and+`;
`Result.all` (list of results → result of list), `Result.map_error`
(check Stdlib first), `Option.or_else`, `Option.get_or ~default`.

**Map / Set**: `Make` functors that `include Stdlib.Map.Make (Ord)` and add
`of_list`, `keys`, `values`, `update_or ~default`, `merge_with`, `find_or
~default`, `group_by`.

**Heap** (new): a pairing heap or leftist heap with a functor
`Heap.Make (Ord : sig type t val compare : t -> t -> int end)`. Persistent API:
`empty`, `add`, `pop_min`, `peek_min`, `of_list`, `to_sorted_list`, `size`.

**Deque** (new): persistent double-ended queue (banker's deque or finger-tree-lite)
with amortized O(1) `push_front`, `push_back`, `pop_front`, `pop_back`.

**Safe** (opt-in):

```ocaml
(* lib/safe.mli *)
val ( = ) : int -> int -> bool
val ( <> ) : int -> int -> bool
val ( < ) : int -> int -> bool
(* ... ( > ) ( <= ) ( >= ) *)
val compare : int -> int -> int
val equal : int -> int -> bool
val min : int -> int -> int
val max : int -> int -> int
module Poly : sig
  val ( = ) : 'a -> 'a -> bool  (* explicit escape hatch *)
  val compare : 'a -> 'a -> int
end
```

After `open Ostd.Safe`, `m1 = m2` on two Maps won't compile. Users write
`Map.equal` or `Safe.Poly.( = )` when they mean it.

### Testing

- Unit tests with alcotest for every function, including edge cases (empty
  input, `n < 0`, separators at string ends).
- Property tests with qcheck for data structures:
  `to_sorted_list (of_list l) = List.sort compare l` for Heap; Deque against a
  reference list model.
- `dune build @doc` must produce clean odoc output. Every public value gets a
  doc comment.

**Done when** every function in `docs/gaps.md` marked "in scope" is implemented,
tested and documented.

## Phase 2 — `ostd-lint` (2–3 weeks)

### How it works

1. User builds their project normally. Dune writes `.cmt` files (typed ASTs)
   by default, in `_build/default/**/.*.objs/byte/`.
2. `ostd-lint _build/default` recursively finds `*.cmt` files.
3. For each file: `Cmt_format.read_cmt`, set up the load path from
   `cmt_loadpath`, take `cmt_annots` (`Implementation structure`), and walk it
   with `Tast_iterator`.
4. On every `Texp_ident (path, _, _)` whose path is a target (below), look at
   the instantiated type of the expression (`exp_type`), take the argument
   type of the arrow, and classify it.
5. Report findings in the compiler's format so editors and CI parse them:

```
File "src/portfolio.ml", line 42, characters 10-11:
Warning SL002 [compare-abstract]: polymorphic (=) on Position.Map.t;
the result depends on internal tree shape. Use Position.Map.equal instead.
```

Exit code: 0 = no findings, 1 = findings, 2 = tool error.

### Targets (`targets.ml`)

`Stdlib.( = )`, `( <> )`, `( < )`, `( > )`, `( <= )`, `( >= )`, `compare`,
`min`, `max`, `Stdlib.List.mem`, `List.assoc`, `List.assoc_opt`,
`List.mem_assoc`, `List.remove_assoc`, `Hashtbl.hash`. Match on
`Path.name` after normalizing (`Stdlib.compare` and `Stdlib__List.mem` both
appear in practice). Catch these used as values too, e.g.
`List.sort compare xs`; the ident is still a `Texp_ident`.

### Classification (`classify.ml`)

Recursive function `classify : Env.t -> type_expr -> verdict` where verdict
is `Safe | Generic | Abstract of Path.t | Functional`.

- Reconstruct the environment at the expression with
  `Envaux.env_of_only_summary exp.exp_env`.
- `Ctype.expand_head env ty`, then match on `Types.get_desc`:
  - `Tarrow` → **Functional** (raises at runtime). Also `Tpackage`
    (first-class modules contain closures).
  - `Tvar` / `Tunivar` → **Generic** (generic code relying on polymorphic
    compare).
  - `Ttuple` → classify each component, return the worst.
  - `Tconstr` with a known-safe builtin path (`int`, `char`, `bool`,
    `unit`, `string`, `bytes`, `float`, `int32`, `int64`, `nativeint`,
    `Uchar.t`) → **Safe**.
  - `Tconstr` with a known-unsafe path (`Map.S.t` instances,
    `Set.S.t`, `Hashtbl.t`, `Lazy.t`) → **Abstract**. Instances of
    `Map.Make(X).t` show up under many paths, so detect by looking up the
    type declaration and checking whether it's abstract.
  - Other `Tconstr`: look up the declaration with `Env.find_type`.
    - Abstract with no manifest → **Abstract**.
    - Record or variant → substitute parameters with `Ctype.apply` and
      classify each field / constructor argument.
    - `list`, `option`, `array`, `result`, `ref` → classify parameters.
  - `Tvariant` (polymorphic variants) → classify row field argument types.
  - `Tobject` → **Abstract** (compared by object id, rarely intended).
- Guard recursion with a set of already-visited type paths so recursive types
  (`type tree = Leaf | Node of tree * tree`) terminate.

### Rules

| ID | Name | Default | Trigger |
|----|------|---------|---------|
| SL001 | compare-functional | error | verdict `Functional` |
| SL002 | compare-abstract | warning | verdict `Abstract` |
| SL003 | compare-generic | off (enable with `--generic`) | verdict `Generic` |

SL003 is off by default because generic code using `=` is common and often
fine. Turning it on is useful for library authors.

### Suppression and config

- Per expression: `(x = y) [@ostd.allow "SL002"]`; check `exp_attributes`
  and walk up enclosing `let` bindings' attributes.
- Per file: a floating `[@@@ostd.allow "SL003"]`.
- CLI: `--only SL001,SL002`, `--format json` (for CI annotations later).

### Version-specific code

`compiler-libs` is not a stable API. `Load_path.init`, `Typedtree`
constructors and `Envaux` change between compiler versions. Rules:

- Keep everything that touches `compiler-libs` in `classify.ml` and a small
  `compat.ml`. Version-gate `compat.ml` with dune
  `(rule (enabled_if (>= %{ocaml_version} 5.2)) ...)` when you add a second
  compiler version.
- `.cmt` files must come from the same compiler version as the linter. Check
  `cmt_version` / the magic number and fail with a clear message (exit 2).

### Testing

Cram tests in `test/lint/`, which compile fixtures directly:

```
  $ ocamlfind ocamlc -bin-annot -c fixtures/maps.ml
  $ ostd-lint .
  File "fixtures/maps.ml", line 3, characters 15-16:
  Warning SL002 [compare-abstract]: ...
  [1]
```

Fixtures to write, one per case:
- functions compared → SL001
- `Map.Make(String).t` and `Hashtbl.t` compared → SL002
- int/string/tuple-of-ints compared → no findings
- record containing a Map compared → SL002 (nested detection)
- recursive variant compared → no findings and no infinite loop
- `List.sort compare` on a list of functions → SL001
- suppression attribute → no findings
- generic `let mem x l = List.exists ((=) x) l` → SL003 only with `--generic`

Then run it on a couple of real projects (your own code, plus one mid-size
open-source OCaml project) and triage false positives before calling it done.

**Done when** all fixtures pass and a real-world run produces no false
positives you can't justify.

## Phase 3 — Release v0.1 (a few days)

- README with a 30-second pitch, install instructions, before/after examples
  for both packages.
- `dune build @doc` and publish odoc to GitHub Pages.
- `CHANGES.md`, license (ISC or MIT, both common in the OCaml ecosystem).
- Tag a release and publish with `opam publish`.
- Announce on discuss.ocaml.org. Expect feedback on naming and overlap with
  Containers, and have the "why not just Containers" answer ready (safety
  story + linter).

## Phase 4 — Later

- **Wider compiler support**: polyfills for older 5.x / 4.14 via dune
  `select`.
- **Linter**: dune alias (`dune build @ostd-lint`), JSON output for GitHub
  annotations, an `Hashtbl.Make`-vs-polymorphic-`Hashtbl` rule, a float
  `=`-on-NaN rule.
- **`ostd-numeric`** (separate package): unboxed float/int64 arrays on
  Bigarray, C stubs for SIMD reductions (sum, dot, min/max), rolling-window
  statistics for time series. Benchmark against plain arrays and Owl with
  `core_bench` or `bechamel` before committing to the API.
- **Friendlier error explainer**: a separate experiment; reuse the cmt
  infrastructure where possible.

## Open decisions

- **Final name.** `ostd` for now. Shortlisted alternatives: cinch, saddle, keel, trellis.
- **`zip` on length mismatch**: raise, truncate, or return an option.
  Stdlib's `List.combine` raises; consistency argues for raising.
- **Heap/Deque**: persistent only, or also mutable versions? Recommend
  persistent only for v0.1.
- **Whether SL001–SL003 belong in zanuda instead.** Decide after the
  prior-art review.

## Milestone checklist

- [ ] Prior-art review done, `docs/gaps.md` written
- [ ] Scaffold builds, CI green
- [ ] List, String, Option, Result extensions + tests
- [ ] Map/Set extensions + tests
- [ ] Heap + Deque + property tests
- [ ] Safe module
- [ ] Linter: reads .cmt, finds target idents
- [ ] Linter: classifier + SL001/SL002/SL003
- [ ] Linter: suppression, CLI flags, version check
- [ ] Linter: cram fixtures pass; real-world triage done
- [ ] README, docs, v0.1 on opam
