(** Stdlib [String], extended.

    Everything from [Stdlib.String] is re-exported unchanged; the values below
    are additions. {b All functions operate on bytes}, not Unicode scalar
    values: lengths, indices and padding count bytes, and "whitespace" means the
    ASCII characters [' '], ['\012'], ['\n'], ['\r'] and ['\t'] (the same set as
    [Stdlib.String.trim]). *)

include module type of Stdlib.String

val split_on : sep:string -> string -> string list
(** [split_on ~sep s] splits [s] on every non-overlapping occurrence of the
    substring [sep], scanning left to right. Separators at the ends produce
    empty strings: [split_on ~sep:", " "a, b, " = ["a"; "b"; ""]], and
    [split_on ~sep "" = [""]]. Raises [Invalid_argument] if [sep] is empty. *)

val replace_all : sub:string -> by:string -> string -> string
(** [replace_all ~sub ~by s] replaces every non-overlapping occurrence of [sub]
    in [s] (scanning left to right) with [by]. Raises [Invalid_argument] if
    [sub] is empty. *)

val find_sub : ?start:int -> sub:string -> string -> int option
(** [find_sub ?start ~sub s] is the byte index of the first occurrence of [sub]
    in [s] at or after [start] (default [0]), or [None]. The empty string is
    found at [start]. Raises [Invalid_argument] if [start] is not a valid
    position in [s] ([0 <= start <= length s]). *)

val contains_sub : sub:string -> string -> bool
(** [contains_sub ~sub s] is [true] iff [sub] occurs in [s]. *)

val pad_left : ?c:char -> int -> string -> string
(** [pad_left ?c n s] prepends copies of [c] (default [' ']) to [s] until it is
    [n] bytes long. Strings already at least [n] bytes long are returned
    unchanged. *)

val pad_right : ?c:char -> int -> string -> string
(** [pad_right ?c n s] is like {!pad_left} but appends. *)

val trim_left : string -> string
(** [trim_left s] is [s] without leading whitespace. *)

val trim_right : string -> string
(** [trim_right s] is [s] without trailing whitespace. *)

val chop_prefix : prefix:string -> string -> string option
(** [chop_prefix ~prefix s] is [Some rest] if [s = prefix ^ rest], else [None].
*)

val chop_suffix : suffix:string -> string -> string option
(** [chop_suffix ~suffix s] is [Some rest] if [s = rest ^ suffix], else [None].
*)

val lines : string -> string list
(** [lines s] splits [s] into lines on ['\n'], removing one trailing ['\r'] from
    each line. A final newline does not produce an empty last line, so
    [lines "a\r\nb\n" = ["a"; "b"]] and [lines "" = []]. *)

val is_blank : string -> bool
(** [is_blank s] is [true] iff [s] is empty or contains only whitespace. *)
