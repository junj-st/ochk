(** Stdlib [List], extended.

    Everything from {!Stdlib.List} is re-exported unchanged; the values below
    are additions. None of them use polymorphic comparison: functions that
    compare elements take an explicit [compare] or [eq] argument. *)

include module type of Stdlib.List

val split_at : int -> 'a list -> 'a list * 'a list
(** [split_at n l] is [(take n l, drop n l)], computed in one pass.
    @raise Invalid_argument if [n < 0]. *)

val chunks : int -> 'a list -> 'a list list
(** [chunks n l] splits [l] into consecutive sublists of length [n]; the last
    one may be shorter. [chunks n [] = []].
    @raise Invalid_argument if [n <= 0]. *)

val windows : int -> 'a list -> 'a list list
(** [windows n l] is every contiguous sublist of [l] of length [n], in order. It
    is [[]] when [l] is shorter than [n].
    @raise Invalid_argument if [n <= 0]. *)

val group_by : ('a -> 'a -> bool) -> 'a list -> 'a list list
(** [group_by eq l] groups {e consecutive} elements of [l] for which
    [eq previous next] holds. [group_by (=) [1; 1; 2; 1] = [[1; 1]; [2]; [1]]].
*)

val last : 'a list -> 'a
(** [last l] is the last element of [l].
    @raise Invalid_argument if [l] is empty. *)

val last_opt : 'a list -> 'a option
(** [last_opt l] is the last element of [l], or [None] if [l] is empty. *)

val sum : int list -> int
(** [sum l] is the sum of the integers in [l] ([0] for [[]]). *)

val sum_float : float list -> float
(** [sum_float l] is the sum of the floats in [l] ([0.] for [[]]), using Kahan
    summation to limit rounding error. *)

val max_by : compare:('a -> 'a -> int) -> 'a list -> 'a option
(** [max_by ~compare l] is a maximal element of [l] according to [compare] (the
    first one on ties), or [None] if [l] is empty. *)

val min_by : compare:('a -> 'a -> int) -> 'a list -> 'a option
(** [min_by ~compare l] is a minimal element of [l] according to [compare] (the
    first one on ties), or [None] if [l] is empty. *)

val dedup : compare:('a -> 'a -> int) -> 'a list -> 'a list
(** [dedup ~compare l] removes duplicates from [l], keeping the first occurrence
    of each element and the original order. Runs in [O(n log n)]. *)

val index_of : eq:('a -> 'a -> bool) -> 'a -> 'a list -> int option
(** [index_of ~eq x l] is the index of the first element [y] of [l] with
    [eq x y], or [None]. *)
