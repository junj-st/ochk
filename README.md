# ostd

**ostd extends the OCaml standard library; it does not replace it.**

Two packages:

- **`ostd`**: the functions Stdlib is still missing (`List.chunks`,
  `String.split_on`, `Result.all`, `Map.S.group_by`, …), a persistent `Heap`
  and `Deque`, and an opt-in `Safe` module that shadows polymorphic
  comparison. Every module starts with `include Stdlib.X`, so a `string`,
  `'a list` or `'a option` is the same type with or without ostd.
- **`ostd-lint`**: a linter that reads your build's `.cmt` files and flags
  polymorphic comparison where it is a bug: on functions (raises at runtime),
  on abstract types like `Map`, `Set` or `Hashtbl` (depends on internal
  layout), and optionally in generic code. It works on any project, with or
  without the library.

Requires OCaml ≥ 5.3. `ostd-lint` must be built with the same compiler as the
code it checks.

## Install

```sh
opam pin add ostd https://github.com/junj-st/ostd.git
opam pin add ostd-lint https://github.com/junj-st/ostd.git
```

```
(libraries ostd)
```

## The library

```ocaml
open Ostd

(* Before *)
let rec chunks n = function
  | [] -> []
  | l -> List.take n l :: chunks n (List.drop n l)

(* After *)
let rows = List.chunks 3 cells
let fields = String.split_on ~sep:", " line
let parsed = Result.all (List.map parse fields)

module SM = Map.Make (String)
let by_owner = SM.group_by (fun p -> p.owner) positions
let counts = SM.update_or word ~default:0 succ counts

module H = Heap.Make (Int)
let smallest = H.(of_list [ 5; 1; 3 ] |> to_sorted_list)   (* [1; 3; 5] *)
```

`open Ostd` changes nothing about comparison. To make polymorphic
comparison a compile error outside `int`, opt in:

```ocaml
open Ostd.Safe

let _ = m1 = m2          (* type error: m1 is not an int *)
let _ = SM.equal Int.equal m1 m2
let _ = Poly.( = ) a b        (* explicit escape hatch *)
```

What is (and is deliberately not) included, and why: [`docs/gaps.md`](docs/gaps.md).
Functions Stdlib 5.3 already has (`List.take`, `Map.of_list`,
`Result.map_error`, …) are not duplicated.

## The linter

```sh
dune build
ostd-lint _build/default
```

```
File "src/portfolio.ml", line 42, characters 10-11:
Warning SL002 [compare-abstract]: polymorphic (=) on int SM.t; SM.t is abstract, so the result depends on its internal representation. Use SM.equal instead.
```

| Rule | Name | Default | Flags |
|---|---|---|---|
| SL001 | compare-functional | error | values containing functions (`=` raises `Invalid_argument`) |
| SL002 | compare-abstract | warning | abstract types: `Map`, `Set`, `Hashtbl`, `Lazy.t`, objects, … |
| SL003 | compare-generic | off (`--generic`) | type variables: generic code relying on polymorphic compare |

Checked identifiers: `=` `<>` `<` `>` `<=` `>=` `compare` `min` `max`
`List.mem` `List.assoc` `List.assoc_opt` `List.mem_assoc`
`List.remove_assoc` `Hashtbl.hash`, including when passed as values
(`List.sort compare fs`). Comparisons against a constant (`l <> []`,
`x = None`) are never reported.

Options: `--generic`, `--only SL001,SL002`, `--format json`.
Exit code: 0 = clean, 1 = findings, 2 = tool error (e.g. `.cmt` from another
compiler version).

Suppress:

```ocaml
let same = (f = g) [@ostd.allow "SL001"]   (* one expression *)
let x = ... [@@ostd.allow]                 (* one binding, all rules *)
[@@@ostd.allow "SL003"]                    (* whole file *)
```

## Why not Containers?

Containers is great and much larger. ostd is deliberately small, adds no new
types, and pairs the library with a safety story: `Ostd.Safe` for code you
own, and `ostd-lint` for code you don't.

## Development

```sh
opam install . --deps-only --with-test
dune build @all @runtest
```

License: MIT.
