Functions compared: SL001, exit 1.

  $ ocamlc -bin-annot -c fixtures/funcs.ml
  $ ochk fixtures/funcs.cmt
  File "fixtures/funcs.ml", line 3, characters 13-14:
  Error SL001 [compare-functional]: polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

Map.Make(String).t and Hashtbl.t compared: SL002.

  $ ocamlc -bin-annot -c fixtures/maps.ml
  $ ochk fixtures/maps.cmt
  File "fixtures/maps.ml", line 5, characters 16-17:
  Warning SL002 [compare-abstract]: polymorphic (=) on int SM.t; SM.t is a Map underneath, so equal contents can compare as different. Use SM.equal instead.
  File "fixtures/maps.ml", line 7, characters 14-21:
  Warning SL002 [compare-abstract]: polymorphic compare on (string, int) Hashtbl.t; Hashtbl.t is a hash table underneath, so equal contents can compare as different. Compare it with a dedicated function instead.
  [1]

Ints, strings, tuples, records, variants, lists, Uchar: no findings.

  $ ocamlfind ocamlc -package unix -bin-annot -c fixtures/safe_types.ml
  $ ochk fixtures/safe_types.cmt

A record containing a map: SL002 (nested detection).

  $ ocamlc -bin-annot -c fixtures/record_map.ml
  $ ochk fixtures/record_map.cmt
  File "fixtures/record_map.ml", line 6, characters 13-14:
  Warning SL002 [compare-abstract]: polymorphic (=) on portfolio, which contains SM.t; SM.t is a Map underneath, so equal contents can compare as different. Use SM.equal instead.
  [1]

Recursive variants: no findings, and it terminates.

  $ ocamlc -bin-annot -c fixtures/rec_variant.ml
  $ ochk fixtures/rec_variant.cmt

List.sort compare on a list of functions: SL001.

  $ ocamlc -bin-annot -c fixtures/sort_funcs.ml
  $ ochk fixtures/sort_funcs.cmt
  File "fixtures/sort_funcs.ml", line 2, characters 23-30:
  Error SL001 [compare-functional]: polymorphic compare on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

Suppression attributes. Only [c], which allows the wrong rule, is reported.

  $ ocamlc -bin-annot -c fixtures/suppressed.ml
  $ ochk fixtures/suppressed.cmt
  File "fixtures/suppressed.ml", line 5, characters 11-12:
  Error SL001 [compare-functional]: polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]
  $ ocamlc -bin-annot -c fixtures/suppressed_file.ml
  $ ochk fixtures/suppressed_file.cmt

Abstract types are judged by what they hide: an int is fine (SL004, off by
default), a Map is SL002, a closure is SL001.

  $ ocamlc -bin-annot -c fixtures/hidden.ml
  $ ochk fixtures/hidden.cmt
  File "fixtures/hidden.ml", line 35, characters 21-22:
  Warning SL002 [compare-abstract]: polymorphic (=) on Env.t; Env.t is a Map underneath, so equal contents can compare as different. Compare it with a dedicated function instead.
  File "fixtures/hidden.ml", line 36, characters 21-22:
  Error SL001 [compare-functional]: polymorphic (=) on Callback.t, which contains functions; this raises Invalid_argument at runtime.
  [1]
  $ ochk --opaque fixtures/hidden.cmt
  File "fixtures/hidden.ml", line 34, characters 20-21:
  Warning SL004 [compare-opaque]: polymorphic (=) on Id.t; Id.t is abstract. Comparing its representation works today (or it is not visible), but bypasses the module's own comparison. Compare it with a dedicated function instead.
  File "fixtures/hidden.ml", line 35, characters 21-22:
  Warning SL002 [compare-abstract]: polymorphic (=) on Env.t; Env.t is a Map underneath, so equal contents can compare as different. Compare it with a dedicated function instead.
  File "fixtures/hidden.ml", line 36, characters 21-22:
  Error SL001 [compare-functional]: polymorphic (=) on Callback.t, which contains functions; this raises Invalid_argument at runtime.
  [1]

The same across files, through an .mli.

  $ ocamlc -bin-annot -I fixtures -c fixtures/abs_lib.mli fixtures/abs_lib.ml fixtures/user.ml
  $ ochk fixtures/user.cmt
  File "fixtures/user.ml", line 2, characters 28-29:
  Warning SL002 [compare-abstract]: polymorphic (=) on Abs_lib.Names.t; Abs_lib.Names.t is a Set underneath, so equal contents can compare as different. Use Abs_lib.Names.equal instead.
  [1]
  $ ochk --opaque fixtures/user.cmt
  File "fixtures/user.ml", line 1, characters 22-23:
  Warning SL004 [compare-opaque]: polymorphic (=) on Abs_lib.t; Abs_lib.t is abstract. Comparing its representation works today (or it is not visible), but bypasses the module's own comparison. Compare it with a dedicated function instead.
  File "fixtures/user.ml", line 2, characters 28-29:
  Warning SL002 [compare-abstract]: polymorphic (=) on Abs_lib.Names.t; Abs_lib.Names.t is a Set underneath, so equal contents can compare as different. Use Abs_lib.Names.equal instead.
  [1]

Generic code: nothing by default, SL003 with --generic.

  $ ocamlc -bin-annot -c fixtures/generic.ml
  $ ochk fixtures/generic.cmt
  $ ochk --generic fixtures/generic.cmt
  File "fixtures/generic.ml", line 1, characters 27-32:
  Warning SL003 [compare-generic]: polymorphic (=) on type variable 'a; generic code relying on polymorphic comparison. Take an equality or compare function as an argument.
  File "fixtures/generic.ml", line 3, characters 27-39:
  Warning SL003 [compare-generic]: polymorphic Hashtbl.hash on type variable k; generic code relying on polymorphic comparison. Take an equality or compare function as an argument.
  File "fixtures/generic.ml", line 9, characters 27-28:
  Warning SL003 [compare-generic]: polymorphic (=) on type variable T.t; generic code relying on polymorphic comparison. Take an equality or compare function as an argument.
  [1]

Functions hidden in nested containers, Seq, objects, lazy values.

  $ ocamlc -bin-annot -c fixtures/nested.ml
  $ ochk fixtures/nested.cmt
  File "fixtures/nested.ml", line 2, characters 13-14:
  Error SL001 [compare-functional]: polymorphic (=) on (int -> int) list list, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 4, characters 10-11:
  Error SL001 [compare-functional]: polymorphic (=) on (int * (unit -> unit)) option, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 5, characters 16-17:
  Error SL001 [compare-functional]: polymorphic (=) on [> `A of int -> int ], which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 7, characters 10-11:
  Error SL001 [compare-functional]: polymorphic (=) on int Seq.t, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 14, characters 12-13:
  Warning SL002 [compare-abstract]: polymorphic (=) on < x : int >; objects are compared by identity, not by contents. Compare them with a dedicated method instead.
  File "fixtures/nested.ml", line 16, characters 11-12:
  Warning SL002 [compare-abstract]: polymorphic (=) on int lazy_t; an unforced lazy value raises Invalid_argument and a forced one compares its result. Force the values and compare the results instead.
  File "fixtures/nested.ml", line 21, characters 23-24:
  Error SL001 [compare-functional]: polymorphic (=) on a, which contains functions; this raises Invalid_argument at runtime.
  File "fixtures/nested.ml", line 22, characters 19-20:
  Error SL001 [compare-functional]: polymorphic (=) on b, which contains functions; this raises Invalid_argument at runtime.
  [1]

Identifiers re-exported through ostd are still caught.

  $ ocamlfind ocamlc -package ostd -bin-annot -c fixtures/via_ostd.ml
  $ ochk fixtures/via_ostd.cmt
  File "fixtures/via_ostd.ml", line 4, characters 8-16:
  Error SL001 [compare-functional]: polymorphic List.mem on int -> int, which contains functions; this raises Invalid_argument at runtime.
  [1]

open Ostd.Safe rejects polymorphic = on strings at compile time.

  $ ocamlfind ocamlc -package ostd -c fixtures/safe_reject.ml > err.txt 2>&1
  [2]
  $ grep -o 'line 5, characters 10-13' err.txt
  line 5, characters 10-13

Directory walk, --only filter, JSON output.

  $ ochk --only SL002 fixtures
  File "fixtures/hidden.ml", line 35, characters 21-22:
  Warning SL002 [compare-abstract]: polymorphic (=) on Env.t; Env.t is a Map underneath, so equal contents can compare as different. Compare it with a dedicated function instead.
  File "fixtures/maps.ml", line 5, characters 16-17:
  Warning SL002 [compare-abstract]: polymorphic (=) on int SM.t; SM.t is a Map underneath, so equal contents can compare as different. Use SM.equal instead.
  File "fixtures/maps.ml", line 7, characters 14-21:
  Warning SL002 [compare-abstract]: polymorphic compare on (string, int) Hashtbl.t; Hashtbl.t is a hash table underneath, so equal contents can compare as different. Compare it with a dedicated function instead.
  File "fixtures/nested.ml", line 14, characters 12-13:
  Warning SL002 [compare-abstract]: polymorphic (=) on < x : int >; objects are compared by identity, not by contents. Compare them with a dedicated method instead.
  File "fixtures/nested.ml", line 16, characters 11-12:
  Warning SL002 [compare-abstract]: polymorphic (=) on int lazy_t; an unforced lazy value raises Invalid_argument and a forced one compares its result. Force the values and compare the results instead.
  File "fixtures/record_map.ml", line 6, characters 13-14:
  Warning SL002 [compare-abstract]: polymorphic (=) on portfolio, which contains SM.t; SM.t is a Map underneath, so equal contents can compare as different. Use SM.equal instead.
  File "fixtures/user.ml", line 2, characters 28-29:
  Warning SL002 [compare-abstract]: polymorphic (=) on Abs_lib.Names.t; Abs_lib.Names.t is a Set underneath, so equal contents can compare as different. Use Abs_lib.Names.equal instead.
  [1]
  $ ochk --format json fixtures/funcs.cmt
  [{"file":"fixtures/funcs.ml","line":3,"start":13,"end":14,"rule":"SL001","name":"compare-functional","severity":"error","message":"polymorphic (=) on int -> int, which contains functions; this raises Invalid_argument at runtime."}]
  [1]

A file that is not a .cmt from this compiler: exit 2.

  $ printf 'not a cmt file' > fixtures/garbage.cmt
  $ ochk fixtures/garbage.cmt
  ochk: fixtures/garbage.cmt: not a .cmt file, or written by a different compiler version (ochk was built with OCaml 5.3.0)
  [2]
  $ rm fixtures/garbage.cmt

Bad flag: exit 2.

  $ ochk --only SL999 fixtures > /dev/null 2>&1
  [2]
