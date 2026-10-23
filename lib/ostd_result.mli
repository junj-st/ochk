(** Stdlib [Result], extended.

    Everything from {!Stdlib.Result} is re-exported unchanged, including
    {!Stdlib.Result.map_error}. *)

include module type of Stdlib.Result

val all : ('a, 'e) result list -> ('a list, 'e) result
(** [all rs] is [Ok vs] if every element of [rs] is [Ok], with values in the
    same order, otherwise the first [Error]. [all [] = Ok []]. *)

(** Binding operators. [let open Result.Syntax in ...] *)
module Syntax : sig
  val ( let* ) : ('a, 'e) result -> ('a -> ('b, 'e) result) -> ('b, 'e) result
  (** [let*] is {!bind}. *)

  val ( let+ ) : ('a, 'e) result -> ('a -> 'b) -> ('b, 'e) result
  (** [let+ x = r in e] is [map (fun x -> e) r]. *)

  val ( and* ) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
  (** [and*] pairs two results; the first [Error] (left to right) wins. *)

  val ( and+ ) : ('a, 'e) result -> ('b, 'e) result -> ('a * 'b, 'e) result
  (** [and+] is the same as [and*]. *)
end
