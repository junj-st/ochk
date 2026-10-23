(** Stdlib [Set], extended.

    Everything from {!Stdlib.Set} is re-exported. {!S} and {!Make} are shadowed
    by versions with extra operations. [Make (Ord).t] is the same type as
    [Stdlib.Set.Make (Ord).t]. *)

include module type of Stdlib.Set

(** Output signature of {!Make}: {!Stdlib.Set.S} plus additions. *)
module type S = sig
  include Stdlib.Set.S

  val union_all : t list -> t
  (** [union_all sets] is the union of every set in [sets] ([empty] for [[]]).
  *)
end

(** Same as {!Stdlib.Set.Make}, with the additions of {!S}. *)
module Make (Ord : OrderedType) :
  S with type elt = Ord.t and type t = Stdlib.Set.Make(Ord).t
