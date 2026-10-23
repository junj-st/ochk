(** Stdlib [Option], extended.

    Everything from [Stdlib.Option] is re-exported unchanged. For a default
    value use [Stdlib.Option.value]. *)

include module type of Stdlib.Option

val or_else : (unit -> 'a option) -> 'a option -> 'a option
(** [or_else f o] is [o] if it is [Some _], otherwise [f ()]. [f] is only called
    when needed, so [o |> Option.or_else (fun () -> fallback ())] is lazy. *)

(** Binding operators. [let open Option.Syntax in ...] *)
module Syntax : sig
  val ( let* ) : 'a option -> ('a -> 'b option) -> 'b option
  (** [let*] is {!bind}. *)

  val ( let+ ) : 'a option -> ('a -> 'b) -> 'b option
  (** [let+ x = o in e] is [map (fun x -> e) o]. *)

  val ( and* ) : 'a option -> 'b option -> ('a * 'b) option
  (** [and*] pairs two options; [None] if either is [None]. *)

  val ( and+ ) : 'a option -> 'b option -> ('a * 'b) option
  (** [and+] is the same as [and*]. *)
end
