(** Persistent double-ended queues (banker's deques).

    Pushing and popping at either end is amortized O(1) when each version of the
    deque is used once (single-threaded use). Repeatedly popping from the same
    old version can cost O(n) per pop. *)

type 'a t
(** A deque of ['a]. *)

val empty : 'a t
(** The empty deque. *)

val is_empty : 'a t -> bool
(** [is_empty d] is [true] iff [d] has no elements. *)

val length : 'a t -> int
(** [length d] is the number of elements of [d]. O(1). *)

val push_front : 'a -> 'a t -> 'a t
(** [push_front x d] adds [x] at the front of [d]. *)

val push_back : 'a t -> 'a -> 'a t
(** [push_back d x] adds [x] at the back of [d]. *)

val pop_front : 'a t -> ('a * 'a t) option
(** [pop_front d] is the front element and the rest, or [None] if empty. *)

val pop_back : 'a t -> ('a t * 'a) option
(** [pop_back d] is the rest and the back element, or [None] if empty. *)

val peek_front : 'a t -> 'a option
(** [peek_front d] is the front element, or [None] if empty. *)

val peek_back : 'a t -> 'a option
(** [peek_back d] is the back element, or [None] if empty. *)

val of_list : 'a list -> 'a t
(** [of_list l] has the elements of [l], the head of [l] at the front. *)

val to_list : 'a t -> 'a list
(** [to_list d] is the elements of [d] from front to back. *)
