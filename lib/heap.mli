(** Persistent priority queues (pairing heaps).

    Elements are ordered by the [compare] function of the functor argument;
    polymorphic comparison is never used. All operations are persistent:
    "modifying" a heap returns a new one and leaves the old one valid. *)

(** Input signature of {!Make}. *)
module type OrderedType = sig
  type t

  val compare : t -> t -> int
end

(** Output signature of {!Make}. *)
module type S = sig
  type elt
  (** Type of elements. *)

  type t
  (** Type of heaps. *)

  val empty : t
  (** The empty heap. *)

  val is_empty : t -> bool
  (** [is_empty h] is [true] iff [h] has no elements. *)

  val size : t -> int
  (** [size h] is the number of elements of [h]. O(1). *)

  val add : elt -> t -> t
  (** [add x h] is [h] with [x] added (duplicates are kept). O(1). *)

  val merge : t -> t -> t
  (** [merge h1 h2] contains the elements of both heaps. O(1). *)

  val peek_min : t -> elt option
  (** [peek_min h] is a smallest element of [h], or [None]. O(1). *)

  val pop_min : t -> (elt * t) option
  (** [pop_min h] is [Some (x, h')] where [x] is a smallest element and [h'] the
      rest, or [None] if [h] is empty. O(log n) amortized. *)

  val of_list : elt list -> t
  (** [of_list l] is a heap containing the elements of [l]. *)

  val to_sorted_list : t -> elt list
  (** [to_sorted_list h] is the elements of [h] in increasing order. *)
end

(** Heap of [Ord.t] ordered by [Ord.compare]. *)
module Make (Ord : OrderedType) : S with type elt = Ord.t
