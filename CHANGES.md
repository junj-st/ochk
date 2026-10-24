## v0.1.0 (unreleased)

- `ostd`: List (`split_at`, `chunks`, `windows`, `group_by`, `last`,
  `last_opt`, `sum`, `sum_float`, `max_by`, `min_by`, `dedup`, `index_of`),
  String (`split_on`, `replace_all`, `find_sub`, `contains_sub`, `pad_left`,
  `pad_right`, `trim_left`, `trim_right`, `chop_prefix`, `chop_suffix`,
  `lines`, `is_blank`), Option (`or_else`, `Syntax`), Result (`all`,
  `Syntax`), Map (`keys`, `values`, `find_or`, `update_or`, `merge_with`,
  `group_by`), Set (`union_all`), persistent `Heap` and `Deque`, opt-in
  `Safe`.
- `ochk`: rules SL001 (compare-functional), SL002 (compare-abstract),
  SL003 (compare-generic), SL004 (compare-opaque), SL005 (compare-nan); abstract types are judged
  by their real representation, found through `.cmt` files;
  `[@ochk.allow]` suppression; `--only`, `--generic`, `--opaque`,
  `--format json`. Surveyed on 47 opam packages (`docs/lint-triage.md`).
