(** Stdlib [Map], extended.

    Everything from [Stdlib.Map] is re-exported. {!S} and {!Make} are shadowed
    by versions with extra operations. [Make (Ord).t] is the same type as
    [Stdlib.Map.Make (Ord).t], so maps flow freely between code that uses ostd
    and code that does not. *)

include module type of Stdlib.Map

(** Output signature of {!Make}: [Stdlib.Map.S] plus additions. *)
module type S = sig
  include Stdlib.Map.S

  val keys : 'a t -> key list
  (** [keys m] is the keys of [m] in increasing order. *)

  val values : 'a t -> 'a list
  (** [values m] is the values of [m], in increasing order of their keys. *)

  val find_or : key -> default:'a -> 'a t -> 'a
  (** [find_or k ~default m] is the value bound to [k], or [default]. *)

  val update_or : key -> default:'a -> ('a -> 'a) -> 'a t -> 'a t
  (** [update_or k ~default f m] binds [k] to [f v], where [v] is the current
      binding of [k] or [default] if there is none.
      [update_or k ~default:0 succ] is a counter increment. *)

  val merge_with : (key -> 'a -> 'a -> 'a) -> 'a t -> 'a t -> 'a t
  (** [merge_with f m1 m2] is the union of [m1] and [m2]; keys bound in both are
      bound to [f k v1 v2]. *)

  val group_by : ('a -> key) -> 'a list -> 'a list t
  (** [group_by key l] maps each [key x] to the elements [x] of [l] with that
      key, in their original order. *)
end

(** Same as [Stdlib.Map.Make], with the additions of {!S}. *)
module Make (Ord : OrderedType) :
  S with type key = Ord.t and type 'a t = 'a Stdlib.Map.Make(Ord).t
