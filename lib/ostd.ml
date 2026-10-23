(** ostd extends the OCaml standard library; it does not replace it.

    [open Ostd] replaces [List], [String], [Option], [Result], [Map] and [Set]
    with extended versions whose types are identical to Stdlib's, and adds
    {!Heap} and {!Deque}. It does not change comparison semantics; for that, opt
    in with [open Ostd.Safe]. *)

module List = Ostd_list
module String = Ostd_string
module Option = Ostd_option
module Result = Ostd_result
module Map = Ostd_map
module Set = Ostd_set
module Heap = Heap
module Deque = Deque
module Safe = Safe
