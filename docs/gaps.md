# Gap analysis (Stdlib 5.3.0)

Each candidate from `PLAN.md` was checked against the Stdlib 5.3.0 `.mli`
files. "Containers" and "Base" list the closest existing function in those
libraries. **Decision** is what ostd v0.1 does.

## List

| Function | Stdlib 5.3 | Containers | Base | Decision |
|---|---|---|---|---|
| `take`, `drop` | `List.take`, `List.drop` (5.3) | `CCList.take/drop` | `List.take/drop` | Stdlib (skip) |
| `take_while`, `drop_while` | `List.take_while/drop_while` (5.3) | yes | yes | Stdlib (skip) |
| `split_at` | — | `take_drop` | `split_n` | in scope |
| `chunks` | — | `chunks` | `chunks_of` | in scope |
| `windows` | — | `sublists_of_len ~offset` | — | in scope |
| `group_by ~eq` (consecutive) | — | `group_succ` | `group` | in scope |
| `last`, `last_opt` | — | `last_opt` | `last`, `last_exn` | in scope |
| `sum`, `sum_float` | — | — | `sum (module Int)` | in scope |
| `max_by`, `min_by` | — | `max/min ~cmp` (via `fold`) | `max_elt ~compare` | in scope |
| `dedup ~compare` (stable) | `sort_uniq` (not stable) | `uniq ~eq` (O(n²)) | `dedup_and_sort` | in scope |
| `index_of ~eq` | `find_index` (predicate) | `find_idx` | `findi` | in scope (thin sugar) |
| `zip`, `unzip` | `combine` (raises on mismatch), `split` | `combine` | `zip`, `unzip` | Stdlib (skip) |

## String (byte-based)

| Function | Stdlib 5.3 | Containers | Base | Decision |
|---|---|---|---|---|
| `split_on ~sep` (substring) | `split_on_char` only | `split ~by` | `Base.String.split ~on:char` | in scope |
| `replace_all ~sub ~by` | — | `replace ~sub ~by` | `substr_replace_all` | in scope |
| `contains_sub` | `contains` (char only) | `mem ~sub` | `is_substring` | in scope |
| `find_sub` | — | `find ~sub` | `substr_index` | in scope |
| `pad_left`, `pad_right` | — | `pad ~side` | `pad_left/right` | in scope |
| `trim_left`, `trim_right` | `trim` (both sides) | `ltrim/rtrim` | `lstrip/rstrip` | in scope |
| `chop_prefix`, `chop_suffix` | `starts_with/ends_with` (bool) | `chop_prefix` | `chop_prefix` | in scope |
| `lines` | — | `lines` | `split_lines` | in scope |
| `is_blank` | — | — | — | in scope |

## Option / Result

| Function | Stdlib 5.3 | Containers | Base | Decision |
|---|---|---|---|---|
| `Option.Syntax` (`let*` `let+` `and+`) | — | `CCOption.Infix` | `Let_syntax` (ppx) | in scope |
| `Option.or_else` | — | `or_lazy` | `first_some` | in scope |
| `Option.get_or ~default` | `Option.value ~default` | `get_or` | `value` | Stdlib (skip) |
| `Result.Syntax` | — | `CCResult.Infix` | `Let_syntax` | in scope |
| `Result.all` | — | `flatten_l` | `all` | in scope |
| `Result.map_error` | `Result.map_error` (4.08) | yes | yes | Stdlib (skip) |

## Map / Set (functor additions)

| Function | Stdlib 5.3 | Containers | Base | Decision |
|---|---|---|---|---|
| `of_list` | `Map.S.of_list` (5.1), `Set.S.of_list` | yes | yes | Stdlib (skip) |
| `keys`, `values` | — (`bindings`) | `keys`, `values` (iter) | `keys`, `data` | in scope |
| `update_or ~default` | `update` (option-based) | `update` | `update` | in scope |
| `merge_with` (total) | `union` (option-returning) | `union` | `merge_skewed` | in scope |
| `find_or ~default` | — (`find_opt`) | `get_or` | `find ~default`-ish | in scope |
| `group_by` | — | — | `of_alist_multi` | in scope |
| `Set.union_all` | — | `of_iter` / fold | `union_list` | in scope |

## New data structures

| Structure | Stdlib 5.3 | Containers | Base/Core | Decision |
|---|---|---|---|---|
| Persistent heap | — (no heap at all) | `CCHeap` | `Pairing_heap` (Core, mutable) | in scope: pairing heap |
| Persistent deque | `Queue` (mutable, one end) | `CCFQueue`, `CCDeque` (mutable) | `Deque` (Core, mutable) | in scope: banker's deque |

## Linter prior art

- **zanuda**: its `use_match_instead_of_equality` lint flags `if x = None`-style
  equality on option/list/bool as a *style* issue. Nothing classifies the
  operand type to catch functional or abstract comparisons, so SL001–SL003 stay
  in `ochk`.
- **Base**: shadows polymorphic compare with `int`-only operators and offers
  `Poly`; `Ostd.Safe` follows the same pattern but is opt-in.

## Out of scope (use an existing library)

Regex → `re`; time → `ptime`; JSON → `yojson`; Unicode → `uutf`/`uucp`.
