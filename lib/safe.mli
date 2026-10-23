(** Opt-in monomorphic comparison.

    [open Ostd.Safe] shadows the polymorphic comparison operators of {!Stdlib}
    with versions restricted to [int]. Comparing two maps, two functions or two
    strings with [=] then fails to compile; use the type's own [equal]/[compare]
    (e.g. [String.equal], [M.equal]) or, when polymorphic comparison is really
    intended, {!Poly}. *)

val ( = ) : int -> int -> bool
(** Integer equality. *)

val ( <> ) : int -> int -> bool
(** Integer inequality. *)

val ( < ) : int -> int -> bool
(** Integer less-than. *)

val ( > ) : int -> int -> bool
(** Integer greater-than. *)

val ( <= ) : int -> int -> bool
(** Integer less-or-equal. *)

val ( >= ) : int -> int -> bool
(** Integer greater-or-equal. *)

val compare : int -> int -> int
(** Integer comparison, as {!Int.compare}. *)

val equal : int -> int -> bool
(** Integer equality, as {!Int.equal}. *)

val min : int -> int -> int
(** Smaller of two integers. *)

val max : int -> int -> int
(** Larger of two integers. *)

(** Explicit escape hatch: the polymorphic operators from {!Stdlib}. *)
module Poly : sig
  val ( = ) : 'a -> 'a -> bool
  (** Polymorphic structural equality, {!Stdlib.( = )}. *)

  val ( <> ) : 'a -> 'a -> bool
  (** {!Stdlib.( <> )}. *)

  val ( < ) : 'a -> 'a -> bool
  (** {!Stdlib.( < )}. *)

  val ( > ) : 'a -> 'a -> bool
  (** {!Stdlib.( > )}. *)

  val ( <= ) : 'a -> 'a -> bool
  (** {!Stdlib.( <= )}. *)

  val ( >= ) : 'a -> 'a -> bool
  (** {!Stdlib.( >= )}. *)

  val compare : 'a -> 'a -> int
  (** {!Stdlib.compare}. *)

  val equal : 'a -> 'a -> bool
  (** Same as {!( = )}. *)

  val min : 'a -> 'a -> 'a
  (** {!Stdlib.min}. *)

  val max : 'a -> 'a -> 'a
  (** {!Stdlib.max}. *)
end
