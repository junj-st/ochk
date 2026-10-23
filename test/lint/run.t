Functions compared: SL001, exit 1.

  $ ocamlc -bin-annot -c fixtures/funcs.ml
  $ ostd-lint fixtures/funcs.cmt
  File "fixtures/funcs.ml", line 3, characters 13-14:
  Error SL001 [compare-functional]: polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

Map.Make(String).t and Hashtbl.t compared: SL002.

  $ ocamlc -bin-annot -c fixtures/maps.ml
  $ ostd-lint fixtures/maps.cmt
  File "fixtures/maps.ml", line 5, characters 16-17:
  Warning SL002 [compare-abstract]: polymorphic (=) on int SM.t; SM.t is abstract, so the result depends on its internal representation. Use SM.equal instead.
  File "fixtures/maps.ml", line 7, characters 14-21:
  Warning SL002 [compare-abstract]: polymorphic compare on (string, int) Hashtbl.t; Hashtbl.t is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  [1]

Ints, strings, tuples, records, variants, lists, Uchar: no findings.

  $ ocamlc -bin-annot -c fixtures/safe_types.ml
  $ ostd-lint fixtures/safe_types.cmt

A record containing a map: SL002 (nested detection).

  $ ocamlc -bin-annot -c fixtures/record_map.ml
  $ ostd-lint fixtures/record_map.cmt
  File "fixtures/record_map.ml", line 6, characters 13-14:
  Warning SL002 [compare-abstract]: polymorphic (=) on portfolio; SM.t is abstract, so the result depends on its internal representation. Use SM.equal instead.
  [1]

Recursive variants: no findings, and it terminates.

  $ ocamlc -bin-annot -c fixtures/rec_variant.ml
  $ ostd-lint fixtures/rec_variant.cmt

List.sort compare on a list of functions: SL001.

  $ ocamlc -bin-annot -c fixtures/sort_funcs.ml
  $ ostd-lint fixtures/sort_funcs.cmt
  File "fixtures/sort_funcs.ml", line 2, characters 23-30:
  Error SL001 [compare-functional]: polymorphic compare on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

Suppression attributes. Only [c], which allows the wrong rule, is reported.

  $ ocamlc -bin-annot -c fixtures/suppressed.ml
  $ ostd-lint fixtures/suppressed.cmt
  File "fixtures/suppressed.ml", line 5, characters 11-12:
  Error SL001 [compare-functional]: polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]
  $ ocamlc -bin-annot -c fixtures/suppressed_file.ml
  $ ostd-lint fixtures/suppressed_file.cmt

Generic code: nothing by default, SL003 with --generic.

  $ ocamlc -bin-annot -c fixtures/generic.ml
  $ ostd-lint fixtures/generic.cmt
  $ ostd-lint --generic fixtures/generic.cmt
  File "fixtures/generic.ml", line 1, characters 27-32:
  Warning SL003 [compare-generic]: polymorphic (=) on type variable 'a; generic code relying on polymorphic comparison. Take an equality or compare function as an argument.
  [1]

Functions hidden in nested containers, Seq, objects, lazy values.

  $ ocamlc -bin-annot -c fixtures/nested.ml
  $ ostd-lint fixtures/nested.cmt
  File "fixtures/nested.ml", line 2, characters 13-14:
  Error SL001 [compare-functional]: polymorphic (=) on (int -> int) list list, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 4, characters 10-11:
  Error SL001 [compare-functional]: polymorphic (=) on (int * (unit -> unit)) option, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 5, characters 16-17:
  Error SL001 [compare-functional]: polymorphic (=) on [> `A of int -> int ], which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 7, characters 10-11:
  Error SL001 [compare-functional]: polymorphic (=) on int Seq.t, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 14, characters 12-13:
  Warning SL002 [compare-abstract]: polymorphic (=) on < x : int >; object is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  File "fixtures/nested.ml", line 16, characters 11-12:
  Warning SL002 [compare-abstract]: polymorphic (=) on int lazy_t; Lazy.t is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  [1]

Identifiers re-exported through ostd are still caught.

  $ ocamlfind ocamlc -package ostd -bin-annot -c fixtures/via_ostd.ml
  $ ostd-lint fixtures/via_ostd.cmt
  File "fixtures/via_ostd.ml", line 4, characters 8-16:
  Error SL001 [compare-functional]: polymorphic List.mem on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

open Ostd.Safe rejects polymorphic = on strings at compile time.

  $ ocamlfind ocamlc -package ostd -c fixtures/safe_reject.ml > err.txt 2>&1
  [2]
  $ grep -o 'line 5, characters 10-13' err.txt
  line 5, characters 10-13

Directory walk, --only filter, JSON output.

  $ ostd-lint --only SL002 fixtures
  File "fixtures/maps.ml", line 5, characters 16-17:
  Warning SL002 [compare-abstract]: polymorphic (=) on int SM.t; SM.t is abstract, so the result depends on its internal representation. Use SM.equal instead.
  File "fixtures/maps.ml", line 7, characters 14-21:
  Warning SL002 [compare-abstract]: polymorphic compare on (string, int) Hashtbl.t; Hashtbl.t is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  File "fixtures/nested.ml", line 14, characters 12-13:
  Warning SL002 [compare-abstract]: polymorphic (=) on < x : int >; object is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  File "fixtures/nested.ml", line 16, characters 11-12:
  Warning SL002 [compare-abstract]: polymorphic (=) on int lazy_t; Lazy.t is abstract, so the result depends on its internal representation. Compare it with a dedicated function instead.
  File "fixtures/record_map.ml", line 6, characters 13-14:
  Warning SL002 [compare-abstract]: polymorphic (=) on portfolio; SM.t is abstract, so the result depends on its internal representation. Use SM.equal instead.
  [1]
  $ ostd-lint --format json fixtures/funcs.cmt
  [{"file":"fixtures/funcs.ml","line":3,"start":13,"end":14,"rule":"SL001","name":"compare-functional","severity":"error","message":"polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime."}]
  [1]

A file that is not a .cmt from this compiler: exit 2.

  $ printf 'not a cmt file' > fixtures/garbage.cmt
  $ ostd-lint fixtures/garbage.cmt
  ostd-lint: fixtures/garbage.cmt: not a .cmt file, or written by a different compiler version (ostd-lint was built with OCaml 5.3.0)
  [2]
  $ rm fixtures/garbage.cmt

Bad flag: exit 2.

  $ ostd-lint --only SL999 fixtures > /dev/null 2>&1
  [2]
