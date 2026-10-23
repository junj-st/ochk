(lang dune 3.14)

(cram enable)

(name ostd)

(generate_opam_files true)

(source
 (github junj-st/ostd))

(license MIT)

(authors "ostd contributors")

(maintainers "junj-st")

(package
 (name ostd)
 (synopsis "A drop-in extension of the OCaml standard library")
 (description
  "ostd extends Stdlib without replacing it: extra List, String, Option, Result, Map and Set functions, persistent Heap and Deque, and an opt-in Safe module that shadows polymorphic comparison.")
 (depends
  (ocaml
   (>= 5.3.0))
  (alcotest :with-test)
  (qcheck-core :with-test)
  (qcheck-alcotest :with-test)))

(package
 (name ostd-lint)
 (synopsis "A linter that catches polymorphic-comparison bugs in OCaml code")
 (description
  "ostd-lint reads the .cmt files dune produces and flags polymorphic comparison (=, compare, List.mem, Hashtbl.hash, ...) on functions, abstract types such as Map and Hashtbl, and optionally generic code.")
 (depends
  (ocaml
   (and
    (>= 5.3.0)
    (< 5.4)))
  (ostd :with-test)
  (ocamlfind :with-test)))
